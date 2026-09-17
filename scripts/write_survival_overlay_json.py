#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Пишет survival_tc_overlay.json из overlay_data.py"""
import json
from pathlib import Path

from overlay_data import OVERLAY

here = Path(__file__).resolve().parent
out = here / "survival_tc_overlay.json"
out.write_text(json.dumps(OVERLAY, ensure_ascii=False, indent=2), encoding="utf-8")
print("Wrote", out, "langs", len(OVERLAY), "keys", len(next(iter(OVERLAY.values()))))
