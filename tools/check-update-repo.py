#!/usr/bin/env python3
"""Check that the public update repository holds exactly what update2.json promises.

    python tools/check-update-repo.py <repo folder> [--rev HEAD | --index]

The in-game updater downloads every file named in update2.json from GitHub and
refuses the whole update when one differs in size or CRC32. What GitHub serves
is what git COMMITTED, which is not always what sits in the folder: with
core.autocrlf on, git stores a CRLF file with LF endings, and the file then
comes back smaller than the manifest says (1.6.0: html/style.css and two
others, "3 of 332 files could not be downloaded or verified").

So this reads each file out of the commit, not off the disk, and compares.
It also refuses an update.json that lists any file: the updaters up to 1.6.0
read that one, and they wreck the resource when they write (see
make-update-manifest.py). Exit code 1 and the names when anything is wrong.
"""
import json
import subprocess
import sys
import zlib


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if not args:
        print(__doc__)
        return 2
    repo = args[0]
    rev = 'HEAD'
    if '--rev' in sys.argv:
        rev = sys.argv[sys.argv.index('--rev') + 1]
    if '--index' in sys.argv:
        rev = ''          # ":<path>" is what is staged, before any commit

    def git(*a, data=None):
        return subprocess.run(['git', '-C', repo] + list(a), input=data, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True).stdout

    manifest = json.loads(git('show', '%s:update2.json' % rev).decode('utf-8'))
    files = manifest['files']
    hold = json.loads(git('show', '%s:update.json' % rev).decode('utf-8'))
    if hold.get('files') != []:
        print('update.json lists %d file(s). It must list none: the updaters up to 1.6.0 read it.' % len(hold.get('files') or []))
        return 1
    if hold.get('version') != manifest.get('version'):
        print('update.json says %s, update2.json says %s' % (hold.get('version'), manifest.get('version')))
        return 1
    # One git process for every file: "<rev>:<path>\n" in, "<sha> blob <size>\n<bytes>\n" out.
    ask = ''.join('%s:%s\n' % (rev, f['path']) for f in files).encode('utf-8')
    out = git('cat-file', '--batch', data=ask)
    pos, bad = 0, []
    for f in files:
        end = out.index(b'\n', pos)
        head = out[pos:end].decode('utf-8', 'replace').split()
        pos = end + 1
        if len(head) < 3 or head[1] != 'blob':
            bad.append('%s: not in the commit' % f['path'])
            continue
        size = int(head[2])
        data = out[pos:pos + size]
        pos += size + 1
        crc = '%08x' % (zlib.crc32(data) & 0xFFFFFFFF)
        if size != f['size']:
            bad.append('%s: committed %d bytes, the manifest says %d' % (f['path'], size, f['size']))
        elif crc != f['crc32']:
            bad.append('%s: committed crc32 %s, the manifest says %s' % (f['path'], crc, f['crc32']))
    if bad:
        print('%d of %d file(s) in the commit differ from update2.json:' % (len(bad), len(files)))
        for line in bad:
            print('  ' + line)
        return 1
    print('%d files in %s match update2.json byte for byte (version %s); update.json lists none' % (len(files), rev or 'the index', manifest.get('version')))
    return 0


if __name__ == '__main__':
    sys.exit(main())
