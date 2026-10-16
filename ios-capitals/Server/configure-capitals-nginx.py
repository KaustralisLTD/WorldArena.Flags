#!/usr/bin/env python3
import pathlib, re, shutil, subprocess, time

site = pathlib.Path('/etc/nginx/sites-available/capital.worldarena.games')
text = site.read_text()
if 'flags.worldarena.games' in text or not re.search(r'server_name\s+capital\.worldarena\.games\s*;', text):
    raise SystemExit('Unexpected Capitals configuration; no changes made.')
include = 'include /opt/worldarena-capitals-api/nginx-capitals-api.conf;'
if include in text:
    raise SystemExit('Capitals API nginx configuration already installed.')
if re.search(r'location\s+(?:=\s+)?/(?:api|profile|\.well-known)', text):
    raise SystemExit('Existing API routes require inspection; no changes made.')
blocks = []
for match in re.finditer(r'\bserver\s*\{', text):
    depth, end = 1, match.end()
    while depth and end < len(text):
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    if depth:
        raise SystemExit('Unbalanced nginx configuration.')
    block = text[match.end():end-1]
    if re.search(r'listen\s+[^;]*\b443\b', block) and re.search(r'server_name\s+capital\.worldarena\.games\s*;', block):
        blocks.append(end-1)
if len(blocks) != 1:
    raise SystemExit('Expected one Capitals HTTPS server; no changes made.')
backup = site.with_name(site.name + '.backup-' + str(int(time.time())))
shutil.copy2(site, backup)
pos = blocks[0]
site.write_text(text[:pos] + '    ' + include + '\n' + text[pos:])
if subprocess.run(['nginx', '-t']).returncode:
    shutil.copy2(backup, site)
    raise SystemExit('nginx validation failed; original configuration restored.')
subprocess.run(['systemctl', 'reload', 'nginx'], check=True)
print('Only Capitals HTTPS routes configured. Backup:', backup)
