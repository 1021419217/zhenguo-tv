#!/usr/bin/env python3
"""真果TV 版本号自动递增：每次改动 +0.1。

单一真源 = pubspec.yaml 的 version 字段（X.Y.Z+N）。flutter build 会自动把它
注入 Info.plist 的 CFBundleShortVersionString / CFBundleVersion，因此只需改这一处，
其余平台（Android / macOS / Windows）版本号也由 Flutter 工具链同步。

MODE = 'minor'（默认）: 1.0.0 → 1.1.0 → 1.2.0 ...（字面 +0.1）
MODE = 'patch'         : 1.0.0 → 1.0.1 → 1.0.2 ...（沿用 quanju-tv 旧的 3.0.1→3.0.4
                          递增习惯时，把下面这一行改成 'patch' 即可）

用法：
  python scripts/bump_version.py                 # 递增并写回，打印新版本号
  python scripts/bump_version.py --dry-run      # 只打印，不写回
  python scripts/bump_version.py --set 2.0.0+9  # 手动设定
"""
import argparse
import re
import sys
from pathlib import Path

MODE = 'minor'
ROOT = Path(__file__).resolve().parents[1]
PUBSPEC = ROOT / 'pubspec.yaml'
LINE = re.compile(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$')


def read_version():
    for line in PUBSPEC.read_text(encoding='utf-8').splitlines():
        m = LINE.match(line)
        if m:
            return tuple(int(m.group(i)) for i in range(1, 5))
    sys.exit('pubspec.yaml 找不到 version: X.Y.Z+N 格式')


def write_version(major, minor, patch, build):
    lines = PUBSPEC.read_text(encoding='utf-8').splitlines(keepends=True)
    for i, line in enumerate(lines):
        if LINE.match(line):
            ending = '\r\n' if line.endswith('\r\n') else ('\n' if line.endswith('\n') else '')
            lines[i] = f'version: {major}.{minor}.{patch}+{build}{ending}'
            break
    PUBSPEC.write_text(''.join(lines), encoding='utf-8')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--set', dest='manual')
    args = ap.parse_args()
    if args.manual:
        m = re.fullmatch(r'(\d+)\.(\d+)\.(\d+)\+(\d+)', args.manual)
        if not m:
            sys.exit('--set 需要 X.Y.Z+N 格式')
        major, minor, patch, build = (int(x) for x in m.groups())
    else:
        major, minor, patch, build = read_version()
        if MODE == 'minor':
            minor += 1
            patch = 0
        else:
            patch += 1
        build += 1
    new = f'{major}.{minor}.{patch}+{build}'
    if not args.dry_run:
        write_version(major, minor, patch, build)
    print(new)


if __name__ == '__main__':
    main()
