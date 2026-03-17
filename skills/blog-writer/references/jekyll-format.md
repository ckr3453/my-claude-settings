# Jekyll 포맷 규칙

## 블로그 저장소

- **경로**: 파일 생성 시점에 사용자에게 1회 확인 (`AskUserQuestion`)
- **테마**: minimal-mistakes (dark skin)
- **permalink**: `/:categories/:title/`

## 카테고리 시스템 — 3개 파일 연동

```
① 포스트 front matter        →  categories: - java
② 카테고리 아카이브 페이지     →  _pages/categories/{섹션}/category-{name}.md
③ 사이드바 네비게이션          →  _includes/nav_list_main
```

폴더 구조(`_posts/programming/java/`)는 정리용일 뿐, Jekyll은 front matter의 `categories:` 값만 본다.

### 카테고리 목록 확인

파일 생성 전에 블로그 저장소의 `_includes/nav_list_main` 파일을 읽어서 현재 카테고리 목록을 동적으로 파악한다. 아래 목록은 fallback 참고용이며, 실제 파일의 내용을 우선한다.

### 참고: 카테고리 목록 (fallback)

| 사이드바 섹션 | 카테고리 (front matter) | 디렉토리 경로 | 사이드바 표시명 |
|-------------|----------------------|--------------|---------------|
| Coding Test | `programmers` | `codingtest/programmers/` | Programmers |
| Coding Test | `baekjoon` | `codingtest/baekjoon/` | Baekjoon |
| Programming | `java` | `programming/java/` | Java |
| Programming | `spring` | `programming/spring/` | Spring Framework |
| Programming | `gis` | `programming/gis/` | GIS |
| Programming | `book` | `programming/book/` | Book review |
| Programming | `data-structure` | `programming/data-structure/` | Data Structure |
| etc | `conference` | `etc/conference/` | Conference/Seminar |
| etc | `motivation` | `etc/motivation/` | Motivation |
| etc | `retrospective` | `etc/retrospective/` | Retrospective |
| etc | `etc` | `etc/etc/` | etc |

---

## 기존 카테고리에 새 글 쓰기

**포스트 파일 1개만 생성하면 끝. 다른 파일 수정 불필요.**

### 파일명 규칙

```
_posts/{카테고리 경로}/YYYY-MM-DD-slug.md
```

- **날짜**: 오늘 날짜 (ISO 8601)
- **slug**: 영문 소문자 + 언더스코어(`_`), 3~6 단어
  - 기존 블로그 관례에 따라 하이픈(`-`) 대신 언더스코어(`_`) 사용
  - 예: "Spring Boot 테스트 삽질기" → `spring_boot_testing_struggle`
  - 예: "Redis vs Memcached 선택기" → `redis_vs_memcached_decision`

### Front Matter

```yaml
---
title: "제목 (한글, 40자 이내)"
categories:
    - 카테고리명
date: YYYY-MM-DD
last_modified_at: YYYY-MM-DD
toc: true
toc_sticky: true
excerpt: "1줄 요약 (80자 이내)"
---
```

### 필드별 규칙

| 필드 | 규칙 |
|------|------|
| `title` | 한글, 40자 이내. 캐주얼 톤 유지 ("~삽질기", "~선택기", "~회고") |
| `categories` | 들여쓰기 리스트 형식. **1개만**. permalink에 영향 |
| `date` | `YYYY-MM-DD` 형식 |
| `last_modified_at` | `YYYY-MM-DD` 형식. 초안 생성 시 date와 동일 |
| `toc` | 항상 `true` |
| `toc_sticky` | 항상 `true` |
| `excerpt` | 1줄 요약. 80자 이내 |

**layout은 생략** — `_config.yml` defaults에서 `single`로 자동 적용됨.

---

## 새 카테고리 만들기

**3단계 필요. 사용자 확인 후 진행.**

### Step 1: 카테고리 아카이브 페이지 생성

파일: `_pages/categories/{섹션}/category-{name}.md`

```yaml
---
title: "표시될 이름"
permalink: /categories/{name}
layout: archive
sidebar_category: true
---

{% assign posts = site.categories.{name} %}
{% for post in posts %} {% include archive-single2.html type=page.entries_layout %} {% endfor %}
```

### Step 2: 사이드바 네비게이션에 추가

파일: `_includes/nav_list_main`

해당 섹션(Coding Test / Programming / etc)의 `</li>` 앞에 추가:

```html
            <ul>
                {% for category in site.categories %}
                    {% if category[0] == "{name}" %}
                        <li><a href="/categories/{name}" class="">{표시명} ({{category[1].size}})</a></li>
                    {% endif %}
                {% endfor %}
            </ul>
```

### Step 3: 포스트 작성

기존 카테고리와 동일 방식으로 `_posts/{섹션}/{name}/` 디렉토리에 포스트 생성.

### 사이드바 섹션 구조

```
nav_list_main 내부 구조:

<span class="nav__sub-title">Coding Test</span>
    → programmers, baekjoon

<span class="nav__sub-title">Programming</span>
    → java, spring, gis, book, data-structure

<span class="nav__sub-title">etc</span>
    → conference, motivation, etc
```

새 섹션이 필요하면 `<li><span class="nav__sub-title">{섹션명}</span>...</li>` 블록 추가.

---

## 본문 마크다운 규칙

- 제목(`#`)은 사용하지 않음 (title이 H1으로 렌더링)
- `##`부터 시작
- 코드 블록: 언어 지정 필수 (```java, ```kotlin 등)
- 내부 링크: 상대경로 사용 안 함 (독립 포스트)
