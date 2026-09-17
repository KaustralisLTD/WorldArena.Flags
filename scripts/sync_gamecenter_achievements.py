#!/usr/bin/env python3
import base64
import hashlib
import json
import mimetypes
import os
import re
import sys
import time
from pathlib import Path
from urllib import parse, request, error


ASC_API_BASE = "https://api.appstoreconnect.apple.com"
DEFAULT_LANGUAGE_MAP = {
    "en": "en-US",
    "ru": "ru",
    "uk": "uk",
    "es": "es-ES",
    "ca": "ca",
    "zh": "zh-Hans",
    "de": "de-DE",
    "fr": "fr-FR",
    "it": "it",
    "pt-BR": "pt-BR",
    "pl": "pl",
    "nl": "nl-NL",
}


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def make_jwt_via_openssl(key_id: str, issuer_id: str, private_key_path: Path) -> str:
    def _read_der_length(b: bytes, i: int) -> tuple[int, int]:
        first = b[i]
        i += 1
        if first & 0x80:
            n = first & 0x7f
            return int.from_bytes(b[i:i + n], "big"), i + n
        return first, i

    def _ecdsa_der_to_raw(signature_der: bytes, size_bytes: int = 32) -> bytes:
        # DER ECDSA signature is: SEQUENCE { r INTEGER, s INTEGER }
        if not signature_der or signature_der[0] != 0x30:
            raise RuntimeError("Unexpected DER signature format (expected ASN.1 SEQUENCE)")
        i = 1
        seq_len, i = _read_der_length(signature_der, i)
        seq_end = i + seq_len

        if i >= len(signature_der) or signature_der[i] != 0x02:
            raise RuntimeError("Unexpected DER signature format (expected INTEGER r)")
        i += 1
        r_len, i = _read_der_length(signature_der, i)
        r = signature_der[i:i + r_len]
        i += r_len

        if i >= len(signature_der) or signature_der[i] != 0x02:
            raise RuntimeError("Unexpected DER signature format (expected INTEGER s)")
        i += 1
        s_len, i = _read_der_length(signature_der, i)
        s = signature_der[i:i + s_len]
        i += s_len

        if i != seq_end:
            raise RuntimeError("Unexpected trailing bytes in DER signature")

        # r/s are signed integers; trim sign-extension 0x00, then left-pad.
        r = r.lstrip(b"\x00") or b"\x00"
        s = s.lstrip(b"\x00") or b"\x00"

        if len(r) > size_bytes:
            r = r[-size_bytes:]
        if len(s) > size_bytes:
            s = s[-size_bytes:]

        r_raw = r.rjust(size_bytes, b"\x00")
        s_raw = s.rjust(size_bytes, b"\x00")
        return r_raw + s_raw

    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    now = int(time.time())
    payload = {"iss": issuer_id, "aud": "appstoreconnect-v1", "iat": now, "exp": now + 19 * 60}
    encoded_header = b64url(json.dumps(header, separators=(",", ":")).encode("utf-8"))
    encoded_payload = b64url(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signing_input = f"{encoded_header}.{encoded_payload}".encode("utf-8")

    import subprocess

    proc = subprocess.run(
        # OpenSSL returns ECDSA signature as ASN.1 DER (SEQUENCE { r, s }).
        # JWT ES256 expects raw signature bytes (r||s, fixed 64 bytes for P-256),
        # so we convert DER -> raw below.
        ["openssl", "dgst", "-sha256", "-sign", str(private_key_path)],
        input=signing_input,
        capture_output=True,
        check=True,
    )
    signature_der = proc.stdout
    signature_raw = _ecdsa_der_to_raw(signature_der, size_bytes=32)
    return f"{encoded_header}.{encoded_payload}.{b64url(signature_raw)}"


def format_error_compact(raw: str) -> str:
    try:
        payload = json.loads(raw or "{}")
        errs = payload.get("errors") or []
        if not errs:
            return (raw or "").strip().replace("\n", " ")[:280]
        first = errs[0]
        code = first.get("code", "UNKNOWN")
        title = first.get("title", "")
        detail = first.get("detail", "")
        compact = f"{code}: {title}"
        if detail:
            compact += f" ({detail})"
        return compact
    except Exception:
        cleaned = re.sub(r"\s+", " ", (raw or "").strip())
        return cleaned[:280]


def log_event(level: str, event: str, **fields):
    payload = {"level": level, "event": event}
    payload.update(fields)
    print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))


def api_request(method: str, path: str, token_provider, body=None):
    token = token_provider()
    url = f"{ASC_API_BASE}{path}"
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = request.Request(url=url, method=method, data=data)
    req.add_header("Authorization", f"Bearer {token}")
    req.add_header("Content-Type", "application/json")
    try:
        with request.urlopen(req, timeout=60) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="ignore")
        if e.code == 401:
            token = token_provider(force_refresh=True)
            req = request.Request(url=url, method=method, data=data)
            req.add_header("Authorization", f"Bearer {token}")
            req.add_header("Content-Type", "application/json")
            try:
                with request.urlopen(req, timeout=60) as resp:
                    raw = resp.read().decode("utf-8")
                    return json.loads(raw) if raw else {}
            except error.HTTPError as e2:
                raw = e2.read().decode("utf-8", errors="ignore")
                raise RuntimeError(
                    f"HTTP {e2.code} {method} {path} :: {format_error_compact(raw)}"
                ) from e2
            except error.URLError as e2:
                raise RuntimeError(f"URL ERROR {method} {path}: {e2}") from e2
        raise RuntimeError(f"HTTP {e.code} {method} {path} :: {format_error_compact(raw)}") from e


def fetch_all(path, token_provider):
    out = []
    next_path = path
    while next_path:
        res = api_request("GET", next_path, token_provider)
        out.extend(res.get("data", []))
        links = res.get("links", {})
        next_url = links.get("next")
        if next_url and next_url.startswith(ASC_API_BASE):
            next_path = next_url[len(ASC_API_BASE):]
        else:
            next_path = None
    return out


def normalize(s: str) -> str:
    return (s or "").strip().lower()


def locale_fallbacks(app_lang: str, mapped_locale: str) -> list[str]:
    out = []
    first = mapped_locale.strip()
    if first:
        out.append(first)
    short_from_lang = app_lang.strip()
    if short_from_lang and short_from_lang not in out:
        out.append(short_from_lang)
    short_from_mapped = first.split("-")[0] if "-" in first else ""
    if short_from_mapped and short_from_mapped not in out:
        out.append(short_from_mapped)
    return out


def resolve_imageset_file(imageset_dir: Path) -> Path | None:
    contents_path = imageset_dir / "Contents.json"
    if not contents_path.exists():
        return None
    try:
        payload = json.loads(contents_path.read_text(encoding="utf-8"))
    except Exception:
        return None
    for item in payload.get("images", []):
        filename = item.get("filename")
        if filename:
            p = imageset_dir / filename
            if p.exists():
                return p
    return None


def upload_to_operations(file_bytes: bytes, operations: list[dict]):
    for op in operations:
        url = op.get("url")
        method = op.get("method", "PUT")
        offset = int(op.get("offset", 0))
        length = int(op.get("length", len(file_bytes) - offset))
        chunk = file_bytes[offset:offset + length]
        req = request.Request(url=url, method=method, data=chunk)
        for header in op.get("requestHeaders", []):
            name = header.get("name")
            value = header.get("value")
            if name and value is not None:
                req.add_header(name, value)
        with request.urlopen(req, timeout=120):
            pass


def ensure_achievement_image(token_provider, localization_id: str, image_file: Path, force_reupload: bool = False):
    related_path = f"/v1/gameCenterAchievementLocalizations/{localization_id}/gameCenterAchievementImage"
    try:
        existing = api_request("GET", related_path, token_provider).get("data")
        if existing and existing.get("id"):
            if not force_reupload:
                return "exists"
            api_request(
                "DELETE",
                f"/v1/gameCenterAchievementImages/{existing['id']}",
                token_provider,
            )
    except RuntimeError as e:
        # Если связи еще нет, ASC часто возвращает 404 — это ок.
        if "HTTP 404" not in str(e):
            raise

    mime, _ = mimetypes.guess_type(str(image_file))
    if not mime:
        mime = "image/png"
    file_bytes = image_file.read_bytes()
    file_md5 = hashlib.md5(file_bytes).hexdigest()

    create_resp = api_request(
        "POST",
        "/v1/gameCenterAchievementImages",
        token_provider,
        {
            "data": {
                "type": "gameCenterAchievementImages",
                "attributes": {
                    "fileName": image_file.name,
                    "fileSize": len(file_bytes),
                },
                "relationships": {
                    "gameCenterAchievementLocalization": {
                        "data": {
                            "type": "gameCenterAchievementLocalizations",
                            "id": localization_id,
                        }
                    }
                },
            }
        },
    )
    image_data = create_resp.get("data", {})
    image_id = image_data.get("id")
    attrs = image_data.get("attributes") or {}
    operations = attrs.get("uploadOperations") or []
    if not image_id:
        raise RuntimeError("Create image response has no id")
    if not operations:
        refreshed = api_request("GET", f"/v1/gameCenterAchievementImages/{image_id}", token_provider)
        attrs = (refreshed.get("data") or {}).get("attributes") or {}
        operations = attrs.get("uploadOperations") or []
    if not operations:
        raise RuntimeError(f"No uploadOperations for image {image_id}")

    upload_to_operations(file_bytes, operations)
    api_request(
        "PATCH",
        f"/v1/gameCenterAchievementImages/{image_id}",
        token_provider,
        {
            "data": {
                "type": "gameCenterAchievementImages",
                "id": image_id,
                "attributes": {
                    "uploaded": True,
                },
            }
        },
    )
    return "uploaded"


def main():
    if len(sys.argv) < 2:
        print("Usage: sync_gamecenter_achievements.py <achievements_json> [--apply] [--force-reupload-images]")
        sys.exit(1)

    payload_path = Path(sys.argv[1])
    apply_mode = "--apply" in sys.argv[2:]
    force_reupload_images = "--force-reupload-images" in sys.argv[2:]

    bundle_id = os.environ.get("APP_IDENTIFIER")
    key_id = os.environ.get("ASC_KEY_ID")
    issuer_id = os.environ.get("ASC_ISSUER_ID")
    private_key = os.environ.get("ASC_KEY_FILEPATH")

    missing = [k for k, v in {
        "APP_IDENTIFIER": bundle_id,
        "ASC_KEY_ID": key_id,
        "ASC_ISSUER_ID": issuer_id,
        "ASC_KEY_FILEPATH": private_key,
    }.items() if not v]
    if missing:
        raise RuntimeError(f"Missing env vars: {', '.join(missing)}")

    private_key_path = Path(private_key)
    token_cache = {"value": None, "exp": 0}

    def token_provider(force_refresh: bool = False):
        now = int(time.time())
        if force_refresh or not token_cache["value"] or now >= token_cache["exp"]:
            token_cache["value"] = make_jwt_via_openssl(key_id, issuer_id, private_key_path)
            token_cache["exp"] = now + 18 * 60
        return token_cache["value"]

    payload = json.loads(payload_path.read_text(encoding="utf-8"))
    achievements = payload.get("achievements", [])
    source_markdown = payload.get("source_markdown")
    if source_markdown:
        repo_root = Path(source_markdown).resolve().parents[2]
    else:
        repo_root = payload_path.resolve().parents[1]
    log_event(
        "INFO",
        "start",
        total=len(achievements),
        mode=("APPLY" if apply_mode else "DRY_RUN"),
        force_reupload_images=force_reupload_images,
        source=str(payload_path),
    )

    apps = api_request("GET", f"/v1/apps?filter[bundleId]={parse.quote(bundle_id)}&limit=2", token_provider).get("data", [])
    if not apps:
        raise RuntimeError(f"App not found by bundle id: {bundle_id}")
    app_id = apps[0]["id"]

    gc_detail_rel = api_request("GET", f"/v1/apps/{app_id}/gameCenterDetail", token_provider).get("data")
    if not gc_detail_rel:
        raise RuntimeError("Game Center detail is missing for this app in App Store Connect.")
    gc_detail_id = gc_detail_rel["id"]

    # `GET /v1/gameCenterAchievements` (collection) может быть запрещён для `gameCenterAchievements`.
    # Для списка достижений конкретного Game Center detail используем V2 endpoint.
    existing = fetch_all(f"/v1/gameCenterDetails/{gc_detail_id}/gameCenterAchievementsV2?limit=200", token_provider)
    by_ref = {normalize((a.get("attributes") or {}).get("referenceName")): a for a in existing}
    by_id = {normalize((a.get("attributes") or {}).get("vendorIdentifier")): a for a in existing}
    created = 0
    updated = 0
    skipped = 0

    for ach in achievements:
        aid = ach["id"]
        ref = ach.get("reference_name") or aid
        ach_created = 0
        ach_updated = 0
        ach_skipped = 0
        ach_locale_updated = 0
        ach_locale_created = 0
        ach_image_uploaded = 0
        ach_image_exists = 0
        ach_image_failed = 0
        match = by_id.get(normalize(aid)) or by_ref.get(normalize(ref))
        attrs_create = {
            "referenceName": ref,
            "vendorIdentifier": aid,
            "points": int(ach["points"]),
            "repeatable": bool(ach["reusable"]),
            "showBeforeEarned": not bool(ach["hidden"]),
        }
        # PATCH на `gameCenterAchievements` у Apple в данном ресурсе не принимает
        # часть атрибутов (vendorIdentifier/reusable/visibleBeforeEarned).
        # Поэтому при UPDATE отправляем минимальный набор полей.
        attrs_patch = {
            "referenceName": ref,
        }

        if match:
            remote_id = match["id"]
            if apply_mode:
                try:
                    api_request(
                        "PATCH",
                        f"/v1/gameCenterAchievements/{remote_id}",
                        token_provider,
                        {
                            "data": {
                                "type": "gameCenterAchievements",
                                "id": remote_id,
                                "attributes": attrs_patch,
                            }
                        },
                    )
                    updated += 1
                    ach_updated += 1
                except RuntimeError as e:
                    # Если API по-прежнему отклоняет атрибуты для UPDATE,
                    # не прерываем весь процесс синка.
                    log_event("WARN", "achievement_update_skipped", achievement=aid, remote_id=remote_id, reason=str(e))
                    skipped += 1
                    ach_skipped += 1
            log_event("INFO", "achievement_update", achievement=aid, remote_id=remote_id)
        else:
            if apply_mode:
                created_resp = api_request(
                    "POST",
                    "/v1/gameCenterAchievements",
                    token_provider,
                    {
                        "data": {
                            "type": "gameCenterAchievements",
                            "attributes": attrs_create,
                            "relationships": {
                                "gameCenterDetail": {
                                    "data": {"type": "gameCenterDetails", "id": gc_detail_id}
                                }
                            },
                        }
                    },
                )
                remote_id = created_resp["data"]["id"]
            else:
                remote_id = f"dryrun-{aid}"
            created += 1
            ach_created += 1
            log_event("INFO", "achievement_create", achievement=aid, remote_id=remote_id)

        localizations = ach.get("localizations", {})
        if not localizations:
            continue

        if apply_mode and not remote_id.startswith("dryrun-"):
            existing_locs = fetch_all(f"/v1/gameCenterAchievements/{remote_id}/localizations?limit=200", token_provider)
            by_locale = {
                normalize((loc.get("attributes") or {}).get("locale")): loc
                for loc in existing_locs
            }
            for app_lang, texts in localizations.items():
                asc_locale = DEFAULT_LANGUAGE_MAP.get(app_lang, app_lang)
                if not texts.get("title"):
                    skipped += 1
                    continue
                # locale нельзя передавать в PATCH existing localization.
                loc_attrs_patch = {
                    "name": texts.get("title", ""),
                    "beforeEarnedDescription": texts.get("before_earned_description", ""),
                    "afterEarnedDescription": texts.get("after_earned_description", ""),
                }
                existing_loc = by_locale.get(normalize(asc_locale))
                if existing_loc:
                    try:
                        api_request(
                            "PATCH",
                            f"/v1/gameCenterAchievementLocalizations/{existing_loc['id']}",
                            token_provider,
                            {
                                "data": {
                                    "type": "gameCenterAchievementLocalizations",
                                    "id": existing_loc["id"],
                                    "attributes": loc_attrs_patch,
                                }
                            },
                        )
                        ach_locale_updated += 1
                    except RuntimeError as e:
                        skipped += 1
                        ach_skipped += 1
                        log_event("WARN", "locale_patch_skipped", achievement=aid, locale=asc_locale, reason=str(e))
                else:
                    posted = False
                    last_error = None
                    for candidate_locale in locale_fallbacks(app_lang, asc_locale):
                        loc_attrs_create = {
                            "locale": candidate_locale,
                            "name": texts.get("title", ""),
                            "beforeEarnedDescription": texts.get("before_earned_description", ""),
                            "afterEarnedDescription": texts.get("after_earned_description", ""),
                        }
                        try:
                            api_request(
                                "POST",
                                "/v1/gameCenterAchievementLocalizations",
                                token_provider,
                                {
                                    "data": {
                                        "type": "gameCenterAchievementLocalizations",
                                        "attributes": loc_attrs_create,
                                        "relationships": {
                                            "gameCenterAchievement": {
                                                "data": {"type": "gameCenterAchievements", "id": remote_id}
                                            }
                                        },
                                    }
                                },
                            )
                            posted = True
                            ach_locale_created += 1
                            break
                        except RuntimeError as e:
                            last_error = e
                            if "ENTITY_ERROR.LOCALE_INVALID" in str(e):
                                continue
                            break
                    if not posted:
                        skipped += 1
                        ach_skipped += 1
                        log_event("WARN", "locale_post_skipped", achievement=aid, locale=asc_locale, reason=str(last_error))
        else:
            log_event("INFO", "locale_dry_run", achievement=aid, localizations=len(localizations))

        imageset = ach.get("asset_imageset_path")
        image_file = None
        if imageset:
            p = Path(imageset)
            if not p.is_absolute():
                p = repo_root / p
            if not p.exists():
                log_event("WARN", "image_set_missing", achievement=aid, path=str(p))
            else:
                image_file = resolve_imageset_file(p)
                if image_file is None:
                    log_event("WARN", "image_file_missing", achievement=aid, path=str(p))

        if apply_mode and image_file and not remote_id.startswith("dryrun-"):
            existing_locs = fetch_all(f"/v1/gameCenterAchievements/{remote_id}/localizations?limit=200", token_provider)
            for loc in existing_locs:
                loc_id = loc.get("id")
                locale = (loc.get("attributes") or {}).get("locale")
                if not loc_id:
                    continue
                try:
                    image_result = ensure_achievement_image(
                        token_provider,
                        loc_id,
                        image_file,
                        force_reupload=force_reupload_images,
                    )
                    if image_result == "uploaded":
                        ach_image_uploaded += 1
                    elif image_result == "replaced":
                        ach_image_uploaded += 1
                    elif image_result == "exists":
                        ach_image_exists += 1
                except RuntimeError as e:
                    skipped += 1
                    ach_skipped += 1
                    ach_image_failed += 1
                    log_event("WARN", "image_upload_skipped", achievement=aid, locale=locale, reason=str(e))

        log_event(
            "INFO",
            "achievement_done",
            achievement=aid,
            created=ach_created,
            updated=ach_updated,
            locale_created=ach_locale_created,
            locale_updated=ach_locale_updated,
            image_uploaded=ach_image_uploaded,
            image_exists=ach_image_exists,
            image_failed=ach_image_failed,
            skipped=ach_skipped,
        )

    log_event("INFO", "done", created=created, updated=updated, skipped=skipped, total=len(achievements))
    if not apply_mode:
        log_event("INFO", "dry_run_complete", hint="Re-run with --apply to send changes to App Store Connect.")


if __name__ == "__main__":
    main()
