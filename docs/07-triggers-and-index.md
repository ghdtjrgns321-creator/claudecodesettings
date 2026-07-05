# 07. Triggers · Index · Git 관리

## 트리거 방식

스킬·에이전트·커맨드가 뜨는 방식:

| 종류     | 트리거                                                      |
| -------- | ----------------------------------------------------------- |
| 스킬     | 각 `SKILL.md`의 `description`을 Claude가 매칭(자동)         |
| 에이전트 | Claude가 필요 시 Task로 파견 / code-reviewer는 완료 후 자동 |
| 커맨드   | 사용자가 `/이름` 직접 입력                                  |

## 목차(INDEX) 운영 방식

시스템이 커져도 놓치지 않도록 **단일 조회처**를 유지한다:

| 목차        | 위치                       | 갱신 시점              |
| ----------- | -------------------------- | ---------------------- |
| 스킬        | `skills/README.md`         | 스킬 추가·삭제·이동 시 |
| 에이전트    | `agents/README.md`         | 에이전트 추가·삭제 시  |
| 시스템 전체 | `docs/01~07` + `README.md` | 구조 변경 시           |
| 결정 기록   | `전역설정-체계.md`         | 의사결정 시            |

**규칙: 스킬·에이전트·훅을 바꾸면 해당 목차를 같은 작업(커밋)에서 갱신한다.**

## Git 관리 (.gitignore 방침)

`~/.claude`를 git으로 관리하되, **시크릿·대용량·런타임은 반드시 제외**한다.

### 커밋 O (설정 자산)
```
CLAUDE.md  README.md  전역설정-체계.md  settings.json  .gitignore
docs/  agents/  skills/(소유분)  hooks/  commands/  rules/  output-styles/  scripts/
```

### 커밋 X (.gitignore)
```
# 시크릿 (절대 금지)
.credentials.json  mcp-needs-auth-cache.json
# 대화·세션
history.jsonl  projects/  sessions/  shell-snapshots/  session-env/
# 개인 메모리
memory/  agent-memory/
# 캐시·런타임
cache/  image-cache/  paste-cache/  downloads/  file-history/
backups/  debug/  ide/  daemon*  jobs/  tasks/
# 플러그인 (마켓 캐시, 재설치로 복원)
plugins/
# 백업·심링크
*.bak  skills/*@(심링크는 ~/.agents 원본)
```

### 유출 방지 순서
```
1) .gitignore 완성·확인
2) git init
3) git add . → git status 로 .credentials.json·history.jsonl 미포함 확인
4) 확인되면 첫 커밋 → remote 연결 → push (리포 private 권장)
```
