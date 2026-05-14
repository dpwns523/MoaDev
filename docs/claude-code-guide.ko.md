# MoaDev — Claude Code 활용 가이드

이 문서는 MoaDev에서 Claude Code 에이전트 설정이 어떻게 작동하는지, 각 파일의 역할이 무엇인지, 그리고 일상적인 개발에서 어떻게 활용하는지 설명합니다.

## 목차

- [개요](#개요)
- [파일 구조](#파일-구조)
- [작동 원리](#작동-원리)
- [개발 플로우](#개발-플로우)
- [서브에이전트 레퍼런스](#서브에이전트-레퍼런스)
- [슬래시 커맨드 레퍼런스](#슬래시-커맨드-레퍼런스)
- [스킬 레퍼런스](#스킬-레퍼런스)
- [설정 방법](#설정-방법)

---

## 개요

MoaDev는 **Claude Code**를 주요 AI 코딩 환경으로 사용합니다. 설정은 여러 계층으로 나뉩니다:

| 계층 | 위치 | 역할 |
|------|------|------|
| 프로젝트 지침 | `CLAUDE.md` | 세션 시작 시 자동 로드 — 핵심 원칙, 기술 스택, 워크플로 규칙 |
| 서브에이전트 | `.claude/agents/*.md` | Task 도구를 통해 스폰되는 도메인 전문 에이전트 |
| 슬래시 커맨드 | `.claude/commands/*.md` | `/커맨드`로 호출하는 단축 워크플로 |
| 스킬 | `.agents/skills/*/SKILL.md` | 필요 시 읽어오는 상세 워크플로 플레이북 |
| 설정 | `.claude/settings.json` | Bash 권한 허용 목록, 환경 변수 |
| Claude 레퍼런스 | `docs/reference/ecc-claude-AGENTS.md` | Claude 전용 보충 가이드 |

설계 철학은 **에이전트 우선, 스킬 기반**입니다. Claude Code는 매 세션마다 `CLAUDE.md`를 읽고, 전문화된 작업은 포커스된 서브에이전트나 스킬 플레이북에 위임합니다.

---

## 파일 구조

```
MoaDev/
├── CLAUDE.md                          ← 프로젝트 지침 (자동 로드)
│
├── .claude/                           ← 로컬 전용, git에 커밋하지 않음
│   ├── settings.json                  ← 권한 및 환경 설정
│   ├── agents/
│   │   ├── explorer.md                ← 읽기 전용 코드베이스 탐색기
│   │   ├── reviewer.md                ← 코드 + 보안 리뷰어
│   │   ├── docs-researcher.md         ← API/프레임워크 문서 검증기
│   │   ├── platform-engineer.md       ← Helm/Terraform/K8s 전문가
│   │   ├── observability-reviewer.md  ← 메트릭/로그/트레이스 전문가
│   │   └── release-manager.md         ← CI/CD 및 GitOps 코디네이터
│   └── commands/
│       ├── tdd.md                     ← /tdd  — TDD 워크플로
│       ├── verify.md                  ← /verify — 전체 검증
│       ├── security.md                ← /security — 보안 체크리스트
│       └── platform.md                ← /platform — 인프라 리뷰
│
├── .agents/skills/                    ← git에 커밋, 팀 공유
│   ├── tdd-workflow/
│   │   ├── SKILL.md                   ← 상세 TDD 지침
│   │   ├── agents/openai.yaml         ← Codex 인터페이스 메타데이터
│   │   └── agents/claude.md           ← Claude Code 인터페이스 메타데이터
│   ├── security-review/
│   ├── verification-loop/
│   └── ... (총 14개 스킬)
│
├── docs/reference/
│   ├── ecc-codex-AGENTS.md            ← Codex CLI 보충 가이드
│   └── ecc-claude-AGENTS.md           ← Claude Code 보충 가이드
│
└── scripts/
    └── install-claude-config.sh       ← .claude/ 초기 설치 스크립트
```

> `.claude/`는 **git에 커밋하지 않습니다** — `scripts/install-claude-config.sh`를 실행해서 생성하는 로컬 전용 설정입니다. 스크립트 자체는 커밋되어 있으므로 어느 개발자도 동일한 환경을 재현할 수 있습니다.

---

## 작동 원리

### 세션 시작

Claude Code를 프로젝트에서 열면 `CLAUDE.md`를 자동으로 읽습니다. 이 파일에는 기술 스택, 사용 가능한 서브에이전트, 스킬, 코딩 표준, 워크플로 규칙이 모두 담겨 있어서 매 세션마다 별도 설정이 필요 없습니다.

### 서브에이전트 스폰

Claude는 **Task 도구**를 사용해 `.claude/agents/`에 정의된 서브에이전트를 생성합니다. 각 서브에이전트는 독립적으로 실행되며 — 새 컨텍스트에서 시작해 해당 `.md` 파일의 지침만 받습니다. 이렇게 하면 비싼 추론 작업을 집중적으로 수행할 수 있습니다:

```
사용자: "인증 플로우에 이메일 인증 추가해줘"
  └─ Claude → explorer 스폰  →  인증 코드 읽기, 결과 리포트
  └─ Claude → docs-researcher 스폰  →  NextAuth v5 API 검증
  └─ Claude → 구현 (explorer 결과를 바탕으로)
  └─ Claude → reviewer 스폰  →  정확성 + 보안 체크
  └─ Claude → /verify 실행  →  빌드, 린트, 테스트, 커버리지 게이트
```

### 스킬 활성화

스킬은 플레이북입니다. Claude는 복잡한 워크플로를 실행하기 전에 관련 `SKILL.md` 파일을 읽습니다. 이것이 바로 "올바른 TDD 방법", "보안 체크리스트" 같은 팀의 지식을 한 번 정의하고 일관되게 재사용하는 방식입니다.

슬래시 커맨드는 스킬의 얇은 래퍼입니다 — `/tdd`는 Claude에게 `tdd-workflow/SKILL.md`를 읽고 따르도록 지시합니다.

---

## 개발 플로우

### 플로우 1: 신규 기능 개발

```
1. Claude Code 실행 → CLAUDE.md 자동 로드
2. Claude에게 기능 설명
3. Claude → explorer 스폰 → 관련 파일 매핑, 데이터 플로우 추적
4. Claude → docs-researcher 스폰 (외부 API 관련 시)
5. /tdd → 실패하는 테스트 먼저 작성 (RED 단계)
6. 테스트가 통과할 때까지 구현 (GREEN 단계)
7. 테스트 유지하면서 리팩토링
8. Claude → reviewer 스폰 → 심각도별 발견 사항 리포트
9. CRITICAL/HIGH 이슈 수정
10. /verify → 빌드 + 타입체크 + 린트 + 테스트 + 보안 스캔
11. 커밋: feat: <설명>
12. PR 오픈
```

### 플로우 2: 버그 수정

```
1. 버그 재현 후 Claude에게 설명
2. Claude → explorer 스폰 → 실행 경로 추적, 근본 원인 발견
3. /tdd → 버그를 잡는 실패 테스트 먼저 작성 (RED 단계)
4. 버그 수정 → 테스트 통과 (GREEN 단계)
5. Claude → reviewer 스폰 → 관련 회귀 버그 체크
6. /verify → 다른 부분이 깨지지 않았는지 확인
7. 커밋: fix: <설명>
```

### 플로우 3: 리팩토링

```
1. 정리할 내용 설명
2. Claude → explorer 스폰 → 모든 사용처와 의존성 파악
3. /tdd → 변경될 코드의 테스트가 존재하는지 확인
4. 작고 검증 가능한 단계로 리팩토링
5. 각 단계 후 테스트 실행
6. Claude → reviewer 스폰 → 동작 회귀 여부 체크
7. /verify → 최종 게이트 통과
8. 커밋: refactor: <설명>
```

### 플로우 4: 인프라 / 플랫폼 변경

```
1. 인프라 변경 사항 설명
2. /platform → Claude → platform-engineer 서브에이전트 스폰
3. 플랫폼 엔지니어 리뷰:
   - 폭발 반경 (blast radius)
   - Helm 차트 정확성
   - Argo CD 연결 상태
   - Terraform 플랜
   - 롤백 안전성
4. 리뷰 결과에 따라 변경 적용
5. /platform 재실행으로 검증
6. 커밋: chore: <설명> 또는 feat: <설명>
```

### 플로우 5: 릴리즈 준비

```
1. "릴리즈 vX.Y.Z 준비해줘" 요청
2. Claude → release-manager 서브에이전트 스폰
3. 릴리즈 매니저 체크:
   - CI 상태
   - 이미지 태깅
   - Helm values 프로모션
   - 릴리즈 노트 완성도
   - 롤백 계획
4. 릴리즈 체크리스트 처리
5. 태그 & 푸시: git tag vX.Y.Z && git push origin vX.Y.Z
```

### 플로우 6: 보안 감사 (모든 PR 전)

```
1. /security → 하드코딩된 시크릿, 인젝션 취약점,
               누락된 인증 체크, 의존성 취약점 스캔
2. PR 오픈 전 CRITICAL 발견 사항 모두 수정
3. /verify로 검증
```

---

## 서브에이전트 레퍼런스

모든 서브에이전트는 기본적으로 **읽기 전용**입니다 — 명시적으로 지시받지 않으면 변경을 가하지 않고 발견 사항만 리포트합니다.

### `explorer` (탐색기)
- **사용 시점**: 코드 변경 전. 파일 매핑, 실행 경로 추적, 의존성 식별
- **모델**: claude-sonnet-4-6
- **리턴**: file:line 참조가 있는 구조화된 증거 리포트

### `reviewer` (리뷰어)
- **사용 시점**: 코드 작성/수정 후. PR 오픈 전.
- **모델**: claude-sonnet-4-6
- **리턴**: 심각도별 발견 사항 (CRITICAL / HIGH / MEDIUM / LOW)

### `docs-researcher` (문서 연구원)
- **사용 시점**: 외부 API 연동 구현 전 또는 낯선 프레임워크 기능 사용 전
- **모델**: claude-sonnet-4-6
- **리턴**: 버전 노트가 포함된 공식 문서 인용 결과

### `platform-engineer` (플랫폼 엔지니어)
- **사용 시점**: Helm, Argo CD, Terraform, Kubernetes 변경 시
- **모델**: claude-sonnet-4-6
- **리턴**: 폭발 반경 평가 + 심각도별 인프라 리뷰

### `observability-reviewer` (관측성 리뷰어)
- **사용 시점**: 메트릭, 로그, 트레이스, 알림, 대시보드 추가 시
- **모델**: claude-sonnet-4-6
- **리턴**: 누락된 계측 리포트 + 알림 품질 평가

### `release-manager` (릴리즈 매니저)
- **사용 시점**: 릴리즈 준비, CI 워크플로 변경, GitOps 프로모션 시
- **모델**: claude-sonnet-4-6
- **리턴**: 릴리즈 체크리스트 상태 + 차단 이슈

---

## 슬래시 커맨드 레퍼런스

| 커맨드 | 활성화 스킬 | 동작 |
|--------|-----------|------|
| `/tdd` | `tdd-workflow` | 실패 테스트 작성 → 구현 → 커버리지 ≥ 80% 검증 |
| `/verify` | `verification-loop` | 빌드 → 타입체크 → 린트 → 테스트 → 보안 스캔 → diff 리뷰 |
| `/security` | `security-review` | 전체 보안 체크리스트: 시크릿, 입력 검증, 인증, 레이트 리밋 |
| `/platform` | — | platform-engineer 서브에이전트 스폰하여 인프라 리뷰 |

### 사용 예시

```
/tdd            → 현재 논의 중인 기능의 TDD 시작
/verify         → PR 오픈 전 실행
/security       → 인증이나 시크릿 관련 변경 시 머지 전 실행
/platform       → platform/ 또는 infra/ 변경 후 실행
```

---

## 스킬 레퍼런스

스킬은 `.agents/skills/`에 위치합니다. 각 스킬에는 Claude가 워크플로를 실행하기 전에 읽는 `SKILL.md`가 있습니다. 스킬은 도구에 독립적입니다 — 동일한 `SKILL.md`가 Claude Code와 Codex CLI 모두에서 작동합니다.

| 스킬 | 트리거 | 핵심 출력물 |
|------|--------|------------|
| `tdd-workflow` | `/tdd`, 신규 기능, 버그 수정 | 커버리지 ≥ 80%의 통과하는 테스트 |
| `security-review` | `/security`, 인증 변경 | 보안 체크리스트 결과 |
| `verification-loop` | `/verify`, PR 전 | 빌드/테스트/린트/보안 리포트 |
| `frontend-patterns` | 컴포넌트/페이지 작업 | React 19 + Next.js 16 베스트 프랙티스 |
| `backend-patterns` | FastAPI 엔드포인트 작업 | 리포지터리 패턴, Pydantic, 비동기 핸들러 |
| `api-design` | 새 REST 엔드포인트 | 일관된 응답 엔벨로프, 버저닝, OpenAPI |
| `python-patterns` | Python 서비스 작업 | 타입 힌트, 에러 처리, 로깅 |
| `python-testing` | pytest 테스트 작성 | 단위 + 통합 테스트 패턴 |
| `database-migrations` | 스키마 변경 | Alembic 마이그레이션 패턴 |
| `e2e-testing` | 핵심 사용자 플로우 | Playwright 테스트 패턴 |
| `deployment-patterns` | 배포 변경 | 배포 안전성 체크리스트 |
| `docker-patterns` | Dockerfile 변경 | 멀티 스테이지 빌드, 보안 |
| `coding-standards` | 코드 품질 리뷰 | 범용 네이밍, 파일 구조, 불변성 |
| `issue-driven-planning` | 복잡한 기능 | 코딩 전 GitHub 이슈 분해 |
| `eval-harness` | 에이전트 평가 작업 | 평가 기반 개발 워크플로 |

---

## 설정 방법

### 최초 설정 (개발자별, 머신별)

```bash
# 1. 레포지터리 클론 — .claude/가 이미 포함되어 있음
git clone <repo-url>
cd MoaDev

# 2. Claude Code 실행
claude

# CLAUDE.md를 자동으로 읽고, .claude/ 안의 에이전트/커맨드가 즉시 사용 가능.
```

별도 설치 스크립트 불필요. `.claude/`는 프로젝트와 함께 커밋되어 있습니다.

### 설정 업데이트

파일을 직접 수정하고 커밋하면 됩니다:

```bash
# 예시: 새 서브에이전트 추가
vim .claude/agents/my-new-agent.md
git add .claude/agents/my-new-agent.md
git commit -m "feat: add my-new-agent subagent"
```

### 커밋하는 파일

| 경로 | 커밋 여부 | 이유 |
|------|-----------|------|
| `CLAUDE.md` | ✅ 커밋 | 프로젝트 전체 AI 컨텍스트 |
| `.claude/agents/` | ✅ 커밋 | 공유 서브에이전트 정의 |
| `.claude/commands/` | ✅ 커밋 | 공유 슬래시 커맨드 |
| `.claude/settings.json` | ✅ 커밋 | 공유 권한 설정 |
| `.agents/skills/` | ✅ 커밋 | 공유 워크플로 플레이북 |
| `docs/reference/ecc-claude-AGENTS.md` | ✅ 커밋 | Claude 전용 가이드 |

---

## Codex CLI와의 차이점

MoaDev는 **Claude Code**와 **Codex CLI** 모두를 지원합니다. 핵심 차이점:

| 기능 | Claude Code | Codex CLI |
|------|------------|-----------|
| 컨텍스트 파일 | `CLAUDE.md` | `AGENTS.md` |
| 설정 파일 | `.claude/settings.json` | `.codex/config.toml` |
| 에이전트 정의 | `.claude/agents/*.md` | `.codex/agents/*.toml` |
| 슬래시 커맨드 | `.claude/commands/*.md` | 지침 기반 |
| Hook 지원 | ✅ (8가지 이벤트 타입) | ❌ |
| 스킬 | `.agents/skills/SKILL.md` 공유 | `.agents/skills/SKILL.md` 공유 |
| 스킬 메타데이터 | `agents/claude.md` | `agents/openai.yaml` |
| 모델 | claude-sonnet-4-6 등 | gpt-5.4 |

스킬의 `SKILL.md` 파일은 양쪽에서 공유됩니다. 도구별 메타데이터(`claude.md` vs `openai.yaml`)만 분리되어 있습니다.
