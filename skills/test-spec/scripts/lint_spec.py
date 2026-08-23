#!/usr/bin/env python3
"""Test Checker 用テスト仕様書(md)の形式を検査する。

使い方: python3 lint_spec.py <spec.md> [...]
終了コード: エラーがあれば 1、無ければ 0。
検査内容はアプリ本体の TestSpecParser と同じ判定ルールに合わせている。
"""
import re
import sys

TASK = re.compile(r"^[-*+]\s+\[[ xX]\]\s+(.+?)\s*$")
INDENTED_TASK = re.compile(r"^\s+[-*+]\s+\[[ xX]\]")
ID_PREFIX = re.compile(r"^([A-Za-z][A-Za-z0-9_]*-\d+)\s+(.+)$")
DETAIL = re.compile(r"^\s+[-*+]\s+(.+?)\s*$")


def lint(path: str) -> list[str]:
    errors: list[str] = []
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")

    # front matter
    has_project = False
    body_start = 0
    if lines and lines[0] == "---":
        try:
            end = lines.index("---", 1)
        except ValueError:
            errors.append(f"{path}:1: front matter が閉じていない")
            end = 0
        has_project = any(re.match(r"^project\s*:\s*\S", l) for l in lines[1:end])
        body_start = end + 1
    if not has_project:
        errors.append(f"{path}:1: front matter に `project: <名前>` がない")

    seen_ids: dict[str, int] = {}
    in_code = False
    case_count = 0
    i = body_start
    while i < len(lines):
        line = lines[i]
        n = i + 1
        i += 1
        if line.startswith("```") or line.startswith("~~~"):
            in_code = not in_code
            continue
        if in_code:
            continue
        if INDENTED_TASK.match(line):
            errors.append(f"{path}:{n}: `- [ ]` がインデントされている(ケースとして認識されない)")
            continue
        m = TASK.match(line)
        if not m:
            continue
        case_count += 1
        idm = ID_PREFIX.match(m.group(1))
        if not idm:
            errors.append(f"{path}:{n}: ID がない(例: `- [ ] LOGIN-001 タイトル`)")
        else:
            cid = idm.group(1)
            if cid in seen_ids:
                errors.append(f"{path}:{n}: ID `{cid}` が重複(初出 {seen_ids[cid]} 行目)")
            seen_ids.setdefault(cid, n)
            if not idm.group(2).strip():
                errors.append(f"{path}:{n}: タイトルが空")
        details: list[str] = []
        while i < len(lines) and (d := DETAIL.match(lines[i])):
            details.append(d.group(1))
            i += 1
        kinds = {d.split(":", 1)[0].strip() for d in details if ":" in d}
        for k in ("手順", "期待"):
            if k not in kinds:
                errors.append(f"{path}:{n}: `- {k}:` がない")
    if case_count == 0:
        errors.append(f"{path}: テストケースが1件もない")
    return errors


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    all_errors: list[str] = []
    for p in sys.argv[1:]:
        all_errors += lint(p)
    for e in all_errors:
        print(e)
    print(f"{len(all_errors)} error(s)")
    return 1 if all_errors else 0


if __name__ == "__main__":
    sys.exit(main())
