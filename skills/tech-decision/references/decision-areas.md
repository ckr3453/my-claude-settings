# 기술 의사결정 영역별 가이드

## 1. 프론트엔드 프레임워크

### 핵심 질문
1. 프로젝트 규모는? (소형/중형/대형 엔터프라이즈)
2. 팀의 JavaScript/TypeScript 숙련도는?
3. SEO가 중요한가?
4. 모바일 앱도 고려 중인가?
5. 기존 프로젝트와의 통합이 필요한가?

### 주요 비교 기준
- **학습 곡선**: 초보자 친화성
- **생태계**: 라이브러리/플러그인 풍부함
- **성능**: 번들 크기, 렌더링 속도
- **커뮤니티**: 활성도, 채용 시장
- **유지보수**: 장기 지원, 업데이트 빈도

### 검색 키워드 템플릿
```
latest {framework} vs {alternative} comparison
recent {framework} production experience
{framework} performance benchmarks current
latest {framework} enterprise adoption
```

### 추천 커뮤니티
- Reddit: r/webdev, r/javascript, r/reactjs, r/vuejs
- Stack Overflow: react, vue, angular 태그
- Dev.to: frontend 카테고리
- Hacker News: Show HN 프로젝트

---

## 2. 백엔드 프레임워크

### 핵심 질문
1. 주 사용 언어는? (Java/Python/Node.js/Go 등)
2. 마이크로서비스 vs 모놀리식?
3. 동시 접속자 규모는?
4. 기존 인프라 제약사항은?
5. 개발 속도 vs 성능 중 우선순위는?

### 주요 비교 기준
- **성능**: 처리량, 응답속도, 메모리 사용량
- **확장성**: 수평/수직 확장 용이성
- **생태계**: ORM, 인증, 캐싱 라이브러리
- **개발 생산성**: 보일러플레이트, 코드 간결성
- **운영 복잡도**: 배포, 모니터링, 디버깅

### 검색 키워드 템플릿
```
latest {framework} scalability best practices
recent {framework} microservices architecture
{framework} vs {alternative} performance current
latest {framework} production deployment
```

### 추천 커뮤니티
- Reddit: r/programming, r/java, r/golang, r/python
- Stack Overflow: spring-boot, express, django 태그
- Dev.to: backend 카테고리
- Hacker News: 시스템 디자인 토론

---

## 3. 데이터베이스

### 핵심 질문
1. 데이터 모델은? (관계형/문서형/그래프)
2. 트랜잭션 요구사항은? (ACID 필수?)
3. 읽기 vs 쓰기 비율은?
4. 데이터 규모는? (GB/TB/PB)
5. 복제/샤딩 전략이 필요한가?

### 주요 비교 기준
- **ACID vs BASE**: 일관성 vs 가용성
- **성능**: 쿼리 속도, 인덱싱 전략
- **확장성**: 수평 확장 지원
- **운영 비용**: 클라우드 요금, 유지보수 인력
- **백업/복구**: 재해 복구 전략

### 검색 키워드 템플릿
```
latest {database} vs {alternative} comparison
recent {database} scaling strategies
{database} ACID consistency current
latest {database} cloud managed service
```

### 추천 커뮤니티
- Reddit: r/database, r/PostgreSQL, r/mongodb
- Stack Overflow: postgresql, mysql, mongodb 태그
- Dev.to: database 카테고리
- Hacker News: 데이터베이스 아키텍처

---

## 4. 인프라/클라우드

### 핵심 질문
1. 클라우드 프로바이더는? (AWS/GCP/Azure/온프레미스)
2. 컨테이너 오케스트레이션 필요? (Kubernetes/ECS)
3. 서버리스 고려 중인가?
4. 예상 트래픽 패턴은?
5. 컴플라이언스 요구사항은? (GDPR/HIPAA)

### 주요 비교 기준
- **비용**: 월 예상 비용, 요금 모델
- **성능**: 네트워크 레이턴시, 컴퓨팅 성능
- **가용성**: SLA, 멀티 리전 지원
- **학습 곡선**: 팀의 기존 역량
- **벤더 락인**: 이식성, 멀티 클라우드 가능성

### 검색 키워드 템플릿
```
latest {provider} cost optimization
recent {provider} reliability best practices
{provider} vs {alternative} performance current
latest {provider} serverless architecture
```

### 추천 커뮤니티
- Reddit: r/devops, r/aws, r/kubernetes
- Stack Overflow: amazon-web-services, kubernetes 태그
- Dev.to: devops, cloud 카테고리
- Hacker News: 인프라 비용 최적화

---

## 5. 기타 영역

### 메시징/이벤트 스트리밍
- Kafka, RabbitMQ, Redis Pub/Sub, AWS SQS/SNS
- 키워드: "latest message queue comparison", "recent kafka vs rabbitmq"

### 캐싱
- Redis, Memcached, CDN (CloudFlare, CloudFront)
- 키워드: "latest redis caching strategies", "recent CDN performance"

### 모니터링/로깅
- Prometheus, Grafana, ELK Stack, Datadog
- 키워드: "latest observability tools", "recent monitoring best practices"

### CI/CD
- GitHub Actions, GitLab CI, Jenkins, CircleCI
- 키워드: "latest CI/CD pipeline best practices", "recent github actions vs gitlab ci"

---

## 검색 전략 (AI용)

### 1단계: 영역 파악
사용자가 어느 영역의 의사결정을 하는지 확인 후, 해당 영역의 핵심 질문 사용.

### 2단계: 키워드 생성
- **범용 키워드 사용**: "latest", "recent", "current", "best practices"
- **특정 연도 지양**: 연도를 명시하지 않아 장기적으로 유효
- **비교 키워드**: "vs", "comparison", "alternatives"

### 3단계: 커뮤니티 검색
각 영역별 추천 커뮤니티에서 우선 검색. 최소 5개 이상의 독립적인 소스 확보.

### 4단계: 필터링
- AI 플랫폼 커뮤니티 결과는 제외
- Stack Overflow에서 높은 투표를 받은 답변 우선

### 5단계: 종합
general-purpose 에이전트에게 수집된 정보를 전달하여 사용자 맥락에 맞는 최종 추천 생성.