#!/usr/bin/env python3
"""PRD.md 구조 검증 — 필수 섹션 존재 + 최소 항목 수 + TBD 카운트(보조).

Usage:
  python check_ambiguity.py <PRD.md path> [--json]

체크 항목 (templates/prd.md 기준):
  - 7개 main 섹션(## 1~7) 작성 여부
  - 1.3 왜 지금 해결해야 하나 — 비어있지 않음
  - 2.1 주 사용자 — 비어있지 않음
  - 3.1 주요 시나리오 ≥ 3개 (서사 문단 또는 - 항목)
  - 4.1 정량 지표 ≥ 1개
  - 5.2 제외 (Out of scope) ≥ 3개
  - 6.1 가정 ≥ 3개
  - 7.1 주요 화면 ≥ 1개 (UI 있는 경우)
  - TBD/미정/모름/나중에 카운트 (보조)

Exit: 0=명확, 1=애매/불충분
"""

import argparse
import json
import re
import sys
from pathlib import Path

CHECKS = [
    ('1.3 왜 지금 해결해야 하나', r'^###\s*1\.3\s+왜 지금', None, 'non_empty'),
    ('2.1 주 사용자', r'^###\s*2\.1\s+주 사용자', None, 'non_empty'),
    ('3.1 주요 시나리오 (≥3)', r'^###\s*3\.1\s+주요 시나리오', 3, 'paragraph_or_bullet'),
    ('4.1 정량 지표 (≥1)', r'^###\s*4\.1\s+정량 지표', 1, 'bullet'),
    ('5.2 Out of scope (≥3)', r'^###\s*5\.2\s+제외', 3, 'bullet'),
    ('6.1 가정 (≥3)', r'^###\s*6\.1\s+가정', 3, 'bullet'),
    ('7.1 주요 화면 (≥1, UI 있는 경우)', r'^###\s*7\.1\s+주요 화면', 1, 'bullet'),
]

TBD_PATTERNS = ['TBD', '미정', '모름', '나중에']


def extract_section(content: str, header_re: str) -> str:
    m = re.search(header_re, content, re.MULTILINE)
    if not m:
        return ''
    start = m.end()
    rest = content[start:]
    next_m = re.search(r'^##\s|^###\s', rest, re.MULTILINE)
    end = next_m.start() if next_m else len(rest)
    return rest[:end].strip()


def is_placeholder(line: str) -> bool:
    """`[...]`로만 된 줄(템플릿 placeholder) 판정."""
    s = re.sub(r'^[-*\d.\s]+', '', line).strip()
    return s.startswith('[') and s.endswith(']')


def count_bullets(section: str) -> int:
    real = []
    for line in section.split('\n'):
        s = line.strip()
        if not s.startswith('-'):
            continue
        if is_placeholder(s):
            continue
        real.append(s)
    return len(real)


def count_paragraphs_or_bullets(section: str) -> int:
    bullets = count_bullets(section)
    paragraphs = [
        p.strip() for p in re.split(r'\n\s*\n', section)
        if p.strip() and not is_placeholder(p.strip())
    ]
    return max(bullets, len(paragraphs))


def is_non_empty(section: str) -> bool:
    text = re.sub(r'\[[^\]]*\]', '', section).strip()
    return len(text) > 0


def check(prd_path: Path) -> dict:
    if not prd_path.exists():
        return {'error': f'파일 없음: {prd_path}'}

    content = prd_path.read_text(encoding='utf-8')
    main_sections = re.findall(r'^##\s+\d+\.', content, re.MULTILINE)

    results = []
    for name, pattern, min_count, mode in CHECKS:
        section = extract_section(content, pattern)
        if not section:
            results.append({'check': name, 'pass': False, 'reason': '섹션 헤더 없음'})
            continue
        if mode == 'non_empty':
            ok = is_non_empty(section)
            results.append({'check': name, 'pass': ok, 'reason': 'OK' if ok else 'placeholder만 있음'})
        elif mode == 'bullet':
            n = count_bullets(section)
            ok = n >= min_count
            results.append({'check': name, 'pass': ok, 'count': n, 'reason': f'{n}개 (요구: {min_count}+)'})
        elif mode == 'paragraph_or_bullet':
            n = count_paragraphs_or_bullets(section)
            ok = n >= min_count
            results.append({'check': name, 'pass': ok, 'count': n, 'reason': f'{n}개 (요구: {min_count}+)'})

    tbd_count = sum(content.count(p) for p in TBD_PATTERNS)

    fail_count = sum(1 for r in results if not r['pass'])
    main_ok = len(main_sections) >= 7
    if main_ok and fail_count == 0:
        verdict = '명확'
    elif fail_count <= 2:
        verdict = '애매'
    else:
        verdict = '불충분'

    return {
        'main_sections_count': len(main_sections),
        'checks': results,
        'tbd_count': tbd_count,
        'verdict': verdict,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description='PRD.md 구조 검증')
    parser.add_argument('prd_path', help='Path to PRD.md')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()

    result = check(Path(args.prd_path))
    if 'error' in result:
        print(result['error'])
        return 1

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0 if result['verdict'] == '명확' else 1

    print(f"7개 main 섹션: {result['main_sections_count']}/7")
    for r in result['checks']:
        mark = '✅' if r['pass'] else '❌'
        print(f"  {mark} {r['check']}: {r['reason']}")
    print(f"\nTBD/미정 표현 (참고): {result['tbd_count']}개")
    print(f"\n판정: {result['verdict']}")

    return 0 if result['verdict'] == '명확' else 1


if __name__ == '__main__':
    sys.exit(main())
