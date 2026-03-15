---
name: ai-trends-report
description: |
  AI 기술 트렌드를 수집/분석하여 이메일로 보고서를 전송하는 스킬.
  국내외 주요 AI 커뮤니티/기사에서 48시간 이내 핵심 이슈를 요약 제공.
  사용 시점: AI 트렌드 리포트 요청, AI 뉴스 수집, /ai-trends-report 명령,
  cron/스케줄러 자동 실행, "AI 소식 알려줘" 같은 요청 시 반드시 이 스킬 사용.
---

# AI Trends Report Skill

AI 기술 트렌드를 수집, 분석하여 마크다운 보고서 생성 후 이메일 전송.

---

## ⛔ 날짜 필터링 (최우선 규칙)

**보고서의 모든 항목에 예외 없이 적용. 위반 시 보고서 품질이 심각하게 저하된다.**

### 허용 범위: 오늘 + 어제 (달력 기준, 2일치)
- ✅ URL/제목에 **오늘 날짜** 또는 **어제 날짜**가 있는 기사
- ✅ 상대 시간 "N시간 전", "1일 전" → 포함
- ❌ **"2일 전" 이상 → 무조건 제외**
- ❌ 날짜 확인 불가 → 제외 (의심되면 버려라)
- ❌ 정보가 부족해도 오래된 글로 채우지 말것. 빈 섹션이 오래된 글보다 낫다.

### 제외 대상
- URL에 오늘/어제가 아닌 날짜 (지난달, 작년 등)
- "YYYY outlook", "YYYY 전망" 등 전망/아웃룩 기사
- "최근", "이번 주", "올해" 같은 모호한 시간 표현만 있는 기사
- "2일 전", "3일 전", "지난주" 등 명확히 2일 이상 지난 기사

### 검색 키워드 규칙
- WebSearch 쿼리에 **어제 날짜**를 포함 (검색엔진 인덱싱 지연 때문)
- 형식: `{검색어} {Month DD, YYYY}` (어제 날짜)
- ❌ 금지: "today", "this week", "recent", "latest", 연도만 단독 사용

---

## 검색 대상 커뮤니티

### 해외 (WebSearch 사용)
| 커뮤니티 | URL | 용도 | 비고 |
|----------|-----|------|------|
| Hacker News | news.ycombinator.com | 개발자 토론 | WebSearch |
| GitHub Trending | github.com/trending | 인기 오픈소스 | WebSearch |
| TechCrunch | techcrunch.com | AI/스타트업 | WebSearch |
| VentureBeat | venturebeat.com | AI 전문 매체 | WebSearch |
| The Verge | theverge.com | 테크 뉴스 | WebSearch |
| Ars Technica | arstechnica.com | 기술 심층 분석 | WebSearch |

※ Reddit, X는 차단되어 WebFetch/WebSearch 불가

### 국내 (WebFetch 직접 크롤링)
| 커뮤니티 | 크롤링 URL | 용도 |
|----------|------------|------|
| **긱뉴스** | https://news.hada.io/new | IT/AI 뉴스 (최적) |
| **요즘IT** | https://yozm.wishket.com/magazine/feed/ | IT 매거진 RSS |
| **velog** | https://velog.io/recent | 개발자 블로그 |
| **OKKY** | https://okky.kr/articles/questions | 개발자 Q&A |
| **ZDNet Korea** | https://zdnet.co.kr/ | IT/AI 전문 뉴스 |
| **IT World Korea** | https://www.itworld.co.kr/ | IT 전문 뉴스 (IDG) |
| **디지털데일리** | https://www.ddaily.co.kr/ | IT/AI 뉴스 |
| **전자신문** | https://www.etnews.com/ | IT/전자 뉴스 |

---

## 보고서 섹션 구조

1. **AI 코딩 에이전트/도구 관련** - Claude Code, Codex, Cursor, Copilot, Windsurf 등 에이전트 및 코딩 도구 뉴스
2. **AI LLM 모델 소식** - LLM 모델 출시/업데이트, 벤치마크 비교, 성능 분석, 모델 관련 논의 등
3. **개발자 커뮤니티 화제** - 국내외 커뮤니티에서 논의되는 AI 관련 토픽
4. **새로운 API/SDK** - 새로 출시된 AI 관련 API/SDK
5. **오픈소스 생태계** - 오픈소스 모델, 도구, GitHub 트렌딩
6. **플랫폼 업데이트** - OpenAI, Anthropic, Google 등 주요 플랫폼 변경
7. **서비스 변경 (중요)** - 가격, 정책, 모델 은퇴 등 중요 변경사항
8. **산업 동향** - M&A, 투자, 규제 등 산업 뉴스
9. **그 외 소식** - 위 섹션에 포함되지 않지만 주목할 만한 AI/기술 소식
10. **추천 읽을거리** - 위 섹션에 포함되지 않은 심층 기사/튜토리얼 (중복 금지)

---

## ⛔ 실행 모드 제약

- **절대 plan mode를 사용하지 말 것. 계획서 작성 없이 즉시 실행할 것.**
- 이 스킬은 비대화형(`-p`) 모드에서 스케줄러로 자동 실행된다.
- plan mode에 진입하면 승인할 사용자가 없어 작업이 완전히 실패한다.
- EnterPlanMode 도구를 절대 호출하지 말 것.

---

## 실행 시작 전 필수 확인

### Step 0: 날짜 확인 (모든 작업 전 반드시 수행)

**Bash로 오늘/어제 날짜를 계산한다:**
```bash
date "+%Y-%m-%d"              # 오늘 ISO (예: 2026-03-12)
date -v-1d "+%Y-%m-%d"        # 어제 ISO (예: 2026-03-11)
date "+%B %d, %Y"             # 오늘 Full (예: March 12, 2026) - 검색 쿼리용
date -v-1d "+%B %d, %Y"      # 어제 Full (예: March 11, 2026) - 검색 쿼리용
date "+%Y/%m/%d"              # 오늘 URL 패턴 (예: 2026/03/12)
date -v-1d "+%Y/%m/%d"       # 어제 URL 패턴 (예: 2026/03/11)
```

**이 값들을 변수처럼 기억하고 이후 모든 검색/필터링에 사용한다.**
- 검색 쿼리: 어제 Full 형식 사용
- URL 검증: 오늘/어제 URL 패턴으로 매칭
- 상대 시간: "N시간 전" ✅, "1일 전" ✅, "2일 전" ❌

---

## ⚠️ 에러 처리 원칙

### 순차 실행 필수
- ❌ **병렬 호출 금지**: WebFetch/WebSearch를 동시에 여러 개 호출하면 하나 실패 시 전체 실패
- ✅ **순차 실행**: 한 번에 하나씩 호출하여 에러 격리
- ✅ **실패 시 계속**: 한 소스 실패해도 다음 소스로 진행

### 요청 간 간격
- WebFetch/WebSearch 호출 사이에 **최소 3초 간격** 유지
- 연속 요청 시 rate limiting 방지 목적

### 재시도 정책
- WebFetch 실패 시 **5초 대기 후 1회 재시도**
- 재시도도 실패 시 → **WebSearch 폴백** (해당 매체명 + 날짜로 검색)
- WebSearch 폴백 예시: `사이트:zdnet.co.kr AI 뉴스 {오늘 날짜}` 또는 `"ZDNet Korea" AI {어제 날짜}`
- WebSearch 폴백도 실패 시 → 해당 소스 건너뛰고 다음 진행

### 에러 대응
- 특정 소스 접근 실패 → 재시도 → 폴백 → 건너뛰고 다음 소스 진행
- 검색 결과 없음 → 해당 섹션 생략 (정상)
- 전체 실패 → "오늘은 데이터를 수집할 수 없습니다" 보고서 생성

---

## 실행 프로세스

### Step 1-A: 국내 커뮤니티 크롤링 (WebFetch - 순차 실행)

**중요: 반드시 순차적으로 하나씩 호출할 것 (병렬 호출 금지)**

**⚠️ WebFetch 프롬프트 핵심 규칙:**
- WebFetch 내부의 소형 모델은 **현재 날짜를 모른다**
- 따라서 프롬프트에 **반드시 오늘/어제의 실제 날짜를 명시**해야 한다
- `{오늘}`, `{어제}`를 Step 0에서 계산한 실제 날짜로 치환할 것

**공통 프롬프트 템플릿:**
```
"오늘은 {오늘 YYYY년 MM월 DD일}이다. 이 페이지에서 AI, LLM, AI 에이전트, AI 도구 관련 글을 찾아서 제목, 날짜/시간, URL을 추출해줘. 반드시 {오늘 MM월 DD일} 또는 {어제 MM월 DD일} 글만 포함하고, 그 이전 날짜의 글은 모두 제외해줘. 날짜를 알 수 없는 글도 제외해줘."
```

**각 소스별 실행 흐름 (공통):**
1. WebFetch 시도
2. 실패 시 → 5초 대기 → WebFetch 재시도 (1회)
3. 재시도 실패 시 → WebSearch 폴백 (`"매체명" AI {어제 날짜}`)
4. 폴백도 실패 시 → 스킵하고 다음 소스 진행
5. **다음 소스로 넘어가기 전 최소 3초 대기**

**1차 - 긱뉴스:**
```
WebFetch: https://news.hada.io/new
프롬프트: (위 공통 프롬프트 템플릿 사용 - 실제 날짜 치환)
폴백: WebSearch "긱뉴스 AI {어제 날짜}"
```

**2차 - 요즘IT:**
```
WebFetch: https://yozm.wishket.com/magazine/feed/
프롬프트: (위 공통 프롬프트 템플릿 사용 - 실제 날짜 치환)
폴백: WebSearch "요즘IT AI {어제 날짜}"
```

**3차 - velog:**
```
WebFetch: https://velog.io/recent
프롬프트: (위 공통 프롬프트 템플릿 사용 - 실제 날짜 치환)
폴백: WebSearch "velog AI {어제 날짜}"
```

**4차 - OKKY:**
```
WebFetch: https://okky.kr/articles/questions
프롬프트: (위 공통 프롬프트 템플릿 사용 - 실제 날짜 치환)
폴백: WebSearch "OKKY AI {어제 날짜}"
```

**5차 - ZDNet Korea:**
```
WebFetch: https://zdnet.co.kr/
프롬프트: (위 공통 프롬프트 템플릿 사용 - 실제 날짜 치환)
폴백: WebSearch "ZDNet Korea AI {어제 날짜}"
```

**6차 - IT World Korea:**
```
WebFetch: https://www.itworld.co.kr/
프롬프트: (위 공통 프롬프트 템플릿 사용 - 실제 날짜 치환)
폴백: WebSearch "ITWorld Korea AI {어제 날짜}"
```

**7차 - 디지털데일리:**
```
WebFetch: https://www.ddaily.co.kr/
프롬프트: (위 공통 프롬프트 템플릿 사용 - 실제 날짜 치환)
폴백: WebSearch "디지털데일리 AI {어제 날짜}"
```

**8차 - 전자신문:**
```
WebFetch: https://www.etnews.com/
프롬프트: (위 공통 프롬프트 템플릿 사용 - 실제 날짜 치환)
폴백: WebSearch "전자신문 AI {어제 날짜}"
```

### Step 1-B: 해외/일반 검색 (WebSearch - 순차 실행)

**중요: 순차적으로 하나씩 호출 (병렬 호출 금지)**

**전략: 매체별이 아닌 토픽별로 검색하여 중복을 줄이고 다양한 내용을 수집한다.**
검색 쿼리에 어제 날짜를 포함 (검색엔진 인덱싱 지연 때문에 어제 날짜가 최신 결과를 더 잘 잡음).

**1. AI 코딩 에이전트/도구** (핵심 토픽 - 반드시 실행):
   - `Claude Code OR Cursor OR Copilot OR Windsurf AI coding {어제 날짜}`
   - `AI coding agent release update {어제 날짜}`

**2. LLM 모델 소식** (핵심 토픽 - 반드시 실행):
   - `new AI model release benchmark {어제 날짜}`
   - `GPT OR Claude OR Gemini OR Llama model update {어제 날짜}`

**3. 플랫폼/서비스 변경**:
   - `OpenAI OR Anthropic OR Google AI announcement {어제 날짜}`
   - `AI API pricing change {어제 날짜}`

**4. 오픈소스/GitHub**:
   - `GitHub trending AI machine learning {어제 날짜}`
   - `open source AI model release {어제 날짜}`

**5. 산업 동향**:
   - `AI startup funding acquisition {어제 날짜}`
   - `AI regulation policy {어제 날짜}`

**6. 커뮤니티 토론** (Hacker News 등):
   - `site:news.ycombinator.com AI {어제 날짜}`

**각 검색마다:** 성공 → 날짜 필터링 적용 / 실패 → 다음 진행 / 결과 없음 → 다음 진행

### Step 1-C: 날짜 필터링 (오늘/어제 기준)

수집한 모든 항목에 대해:
1. URL에 Step 0의 오늘/어제 날짜 패턴이 있는가? → ✅
2. "N시간 전", "1일 전" 표시가 있는가? → ✅
3. "2일 전" 이상, 날짜 불명확, 오래된 날짜 → ❌ 제외

**의심스러우면 제외. 빈 섹션이 오래된 글보다 낫다.**

### Step 1-D: AI 관련성 필터링

**핵심 질문: "AI/ML이 이 항목의 핵심 주제인가?"**
- ✅ Yes → 포함
- ❌ AI가 부수적으로 언급될 뿐 → 제외

**포함 예시:** AI 모델, AI 코딩 도구, AI 플랫폼, MCP/에이전트, AI API/SDK, AI 산업(투자/M&A)
**제외 예시:** 일반 프로그래밍 언어, AI 무관 API 변경, 일반 보안/프라이버시 도구, 일반 개발 뉴스

### Step 2: 보고서 생성

- 파일명: `ai_trends_report_YYYYMMDD.md`
- 저장 위치: `/tmp/`

### Step 3: 이메일 전송

```bash
python ~/.claude/skills/ai-trends-report/scripts/send_email.py \
  --config ~/.claude/skills/ai-trends-report/scripts/config.json \
  --report "<report_path>"
```

---

## 보고서 템플릿

```markdown
# AI 트렌드 리포트
**YYYY-MM-DD**

---

## AI 코딩 에이전트/도구 관련

#### [에이전트/도구명] - [뉴스/업데이트/사례] (날짜)
[Claude Code, Codex, Cursor, Copilot, Windsurf 등 에이전트 및 코딩 도구 관련 소식]
[URL]

---

## AI LLM 모델 소식

#### [모델명] - [제공자] (날짜)
[모델 출시/업데이트, 벤치마크 비교, 성능 분석, 모델 관련 논의 등 핵심 요약]
[URL]

---

## 개발자 커뮤니티 화제

#### [토픽 제목] (날짜)
[설명]
[URL]

---

## 새로운 API/SDK

#### [API/SDK명] - [제공자] (날짜)
[설명]
[URL]

---

## 오픈소스 생태계

#### [모델/도구명] - [제공자/스타 수] (날짜)
[오픈소스 모델, 도구, GitHub 트렌딩 등]
[URL]

---

## 플랫폼 업데이트

#### [플랫폼명] - [업데이트 내용] (날짜)
[설명]
[URL]

---

## 서비스 변경 (중요)

#### [변경 제목] - (날짜)
[변경 내용]

---

## 산업 동향

#### [회사/주제] - [내용] (날짜)
[설명]

---

## 그 외 소식

#### [제목] (날짜)
[설명]
[URL]

---

## 추천 읽을거리

- [제목] (날짜)
  [URL]

---

**생성 도구**: Claude Code AI Trends Report Skill
**생성일**: YYYY-MM-DD
```

---

## 보고서 작성 규칙

1. **한국어 작성**, 각 항목 2-3문장 핵심 요약
2. **출처 명시**: 모든 항목에 URL 포함, 날짜 없으면 제외
3. **중복 제거 (엄격 적용)**:
   - 동일 URL 절대 2번 등장 금지
   - **같은 사건/발표를 다른 매체가 보도한 경우 → 1개만 채택** (가장 상세한 원문 우선)
   - 추천 읽을거리에는 다른 섹션 항목 절대 금지
   - 보고서 완성 후 전체 URL 목록을 검토하여 중복 제거
4. **섹션 생략**: 오늘/어제 글이 없는 섹션은 생략 (빈 섹션 > 오래된 글)
5. **내용 없으면 솔직하게**: "오늘은 특별한 소식이 없습니다" 표기
6. **각 항목의 핵심 가치를 명확히**: "무엇이 발표/변경되었고, 왜 중요한지"를 반드시 포함

## ⛔ 최종 체크리스트 (보고서 생성 전 확인)
- ⛔ 2일 전 이상의 항목 없는가? (Step 0의 오늘/어제 날짜로 검증)
- ⛔ AI 무관 항목 없는가?
- ⛔ 동일 URL 중복 없는가?
- ⛔ 같은 사건을 여러 항목으로 반복 기술하지 않았는가?

---

## 이메일 설정

`scripts/config.json` 필요 (Gmail 앱 비밀번호 사용)
