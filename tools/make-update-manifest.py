#!/usr/bin/env python3
"""
Writes update2.json (and the announcement-only update.json) for a release
folder, for the in-resource updater.

    python tools/make-update-manifest.py <release folder> [--out <file>]

TWO FILES, ON PURPOSE. update2.json is the manifest: every file with its
size and CRC32. update.json is what the updaters up to 1.6.0 read, and it
must NEVER list a file again: those updaters cut every binary file at its
first zero byte when they write it and wreck the resource (it happened on
2026-11-24). So update.json carries the version and the changelog, led by a
line that says to download from the Cfx portal, and an empty file list,
which those updaters answer with "manifest lists no files" and no writes.

<release folder> is the resource as customers run it -- the ESCROWED build
downloaded from Keymaster after upload, not the source tree -- with
fxmanifest.lua at its top. The manifest lists every file with its size and
CRC32 (the same CRC32 server/update.lua computes), the version from
fxmanifest.lua, and the newest section of CHANGELOG.md as the changelog.

Never listed, by rule: data/ (the customer's decorations and settings),
the two manifests themselves, tools/, docs/, dist/, anything starting with a
dot except .fxap (the escrow key file, so that an updated folder is the Cfx
download byte for byte).

Publish: commit the release folder's contents and this update.json to the
root of the public repository named in Settings -> Updates, on the branch
named there. Customers' servers fetch
    https://raw.githubusercontent.com/<owner>/<repo>/<branch>/update2.json
and each listed file from the same base.
"""
import json
import os
import re
import sys
import zlib
from datetime import date

SKIP_DIRS = {'data', 'tools', 'docs', 'dist', '.git', '__pycache__', 'node_modules'}
SKIP_FILES = {'update.json', 'update2.json', 'package.ps1', '.gitignore'}
KEEP_DOTFILES = {'.fxap'}
HOLD_NOTE = ('IMPORTANT: this version cannot be installed from inside the game with the version you are running. '
             'Download it from your Cfx portal, copy it over the old folder (keep your data folder), '
             'type refresh, then restart sals_kewlholidays. In-game updates work again from 1.6.1 on.')


def version_of(root):
    text = open(os.path.join(root, 'fxmanifest.lua'), encoding='utf-8').read()
    m = re.search(r"^\s*version\s+'([^']+)'", text, re.M)
    if not m:
        raise SystemExit('fxmanifest.lua has no version line')
    return m.group(1)


def changelog_of(root, version):
    path = os.path.join(root, 'CHANGELOG.md')
    if not os.path.exists(path):
        return []
    lines = open(path, encoding='utf-8').read().splitlines()
    out, inside = [], False
    for line in lines:
        if line.startswith('## '):
            if inside:
                break
            inside = version in line
            continue
        if inside:
            s = line.strip()
            if s.startswith('- '):
                out.append(s[2:])
            elif s and out and not s.startswith('#'):
                out[-1] += ' ' + s
    return out[:12]


def main():
    args = sys.argv[1:]
    if not args:
        raise SystemExit(__doc__)
    root = os.path.abspath(args[0])
    out = os.path.join(root, 'update2.json')
    if '--out' in args:
        out = os.path.abspath(args[args.index('--out') + 1])
    if not os.path.exists(os.path.join(root, 'fxmanifest.lua')):
        raise SystemExit('not a resource folder (no fxmanifest.lua): ' + root)

    version = version_of(root)
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        rel_dir = os.path.relpath(dirpath, root).replace('\\', '/')
        parts = [] if rel_dir == '.' else rel_dir.split('/')
        if parts and (parts[0] in SKIP_DIRS or parts[0].startswith('.')):
            dirnames[:] = []
            continue
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith('.')]
        for name in sorted(filenames):
            if name in SKIP_FILES or (name.startswith('.') and name not in KEEP_DOTFILES):
                continue
            full = os.path.join(dirpath, name)
            rel = (rel_dir + '/' + name) if parts else name
            data = open(full, 'rb').read()
            files.append({'path': rel, 'size': len(data), 'crc32': '%08x' % (zlib.crc32(data) & 0xFFFFFFFF)})

    doc = {
        'version': version,
        'published': date.today().isoformat(),
        'changelog': changelog_of(root, version),
        'files': files,
    }
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(doc, f, indent=2)
        f.write('\n')
    # The announcement for the updaters that must not write: no files, ever.
    hold = dict(doc, changelog=[HOLD_NOTE] + doc['changelog'][:11], files=[])
    with open(os.path.join(os.path.dirname(out), 'update.json'), 'w', encoding='utf-8', newline='\n') as f:
        json.dump(hold, f, indent=2)
        f.write('\n')
    total = sum(f['size'] for f in files)
    print(f'{out}: version {version}, {len(files)} files, {total // 1024} KB')


if __name__ == '__main__':
    main()
