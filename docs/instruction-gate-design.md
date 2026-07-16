# 지시 강제 게이트 — 상세 설계서 (구버전)

> 이 설계는 더 이상 쓰이지 않는다. 현행 게이트 → [08a-completion-contract.md](08a-completion-contract.md)

> 목적: "전역 문서를 갱신해도 안 지켜진다"는 문제를, 권고(CLAUDE.md)가 아니라 **결정론 훅**으로 강제한다.

---

## 0. 막는 사례와 한계

**막는 2종**

| 사례                    | 증상                                   | 게이트                                   |
| ----------------------- | -------------------------------------- | ---------------------------------------- |
| A형 산출물 누락         | "전부 하라" → 일부만 하고 종료         | contract 미체크 `[ ]` → Stop 차단        |
| B형 하드코딩/단일케이스 | 1케이스 통과 코딩 → 다른 케이스서 버그 | "2+ 케이스 검증" 필수 항목 + 리터럴 경고 |

**설계 한계 (반드시 명시)**
- 이 시스템은 **"조용히 건너뛰기"의 바닥**이다. 완전성 증명이 아니다.
- lazy contract(적게 선언)는 못 막는다 — 게이트는 "선언한 걸 했나"를 보지, "옳게 선언했나"는 못 본다.
  - **보강(①, contract_lint.py)**: "loose 선언"의 한 종류 — 측정 근거(수치·비교·실패조건·파일경로) 없는 검증/분석 동사형 `[x]` 항목 — 은 형식 검출로 Stop에서 차단한다. 의미 깊이(엉뚱한 수치)는 여전히 못 본다 → 착수 전 적대적 self-검수(②, discipline 주입)로 보완.
- "산출물 작업인가" 판정은 휴리스틱이다 — contract를 아예 안 만들면 게이트가 안 걸린다(미작성 = 미강제). 이건 discipline 주입(soft)으로만 압박한다. v2에서 transcript 스캔으로 보강 가능.

---

## 1. 아키텍처

```
                CLAUDE.md (원칙·권고, 짧게)
                  A: 전수가 기본 / B: 구동값은 입력에서
                              │
작업 시작 ── UserPromptSubmit ─┤ completion_discipline.sh
                              │   "산출물 작업이면 contract.md에 [ ] 체크리스트.
                              │    코딩이면 '2+ 케이스 검증' 필수." (soft 트리거)
                              │
코딩 중  ── PostToolUse ───────┤ literal_lint.py (경고만)
            (Write|Edit)      │   연도/긴ID/거대상수 박히면 경고 주입
                              │
작업 종료 ── Stop ─────────────┤ completion_gate.sh (강경, 결정론)
                              │   contract.md 파싱:
                              │     미체크 [ ] 있으면 → block
                              │     [x]/[~]사유/OVERRIDE → pass
                              │     같은 contract N회 연속 차단 → 경고로그+자동통과
```

**결정 5개 (잠금)**

| 항목          | 값                                                                       |
| ------------- | ------------------------------------------------------------------------ |
| 차단 강도     | 강경 (미체크 `[ ]` → 차단)                                               |
| 체크박스      | `[ ]`차단 / `[x]`통과 / `[~]사유`통과                                    |
| 탈출구        | `[~]사유`·`OVERRIDE:사유` + N회(=3) 연속 차단 시 경고로그 후 자동통과    |
| 리터럴 린트   | 경고만 (연도/긴ID≥6자리/거대상수≥1e6, config·test·주석 제외)             |
| contract 경로 | `{cwd}/.claude/state/contract.md` (홈/비쓰기 시 `~/.claude/state/` 폴백) |

---

## 2. contract.md 포맷

경로: `{state_dir}/contract.md` (state_dir = `{cwd}/.claude/state` 또는 폴백 `~/.claude/state`)

```markdown
# Task Contract
task: <한 줄 작업 설명>

## Deliverables
- [ ] <셀 수 있는 산출물 1: 어느 파일/항목 N개, 무슨 표·목록·정량값>
- [ ] <셀 수 있는 산출물 2>
- [ ] 2+ 케이스로 검증 (ripple-search)        ← 코딩작업이면 필수

## Notes
<축소 사유는 해당 항목을 [~]로 바꾸고 괄호에 사유. 전체 포기는 아래 한 줄.>
```

**상태 판정(게이트가 보는 것)**
- `- [ ]` (raw, 미체크) 1개라도 존재 → **미완**
- 모든 항목이 `- [x]`(완료) 또는 `- [~]`(축소+사유) → **완료**
- `OVERRIDE: <사유>` 줄 존재 → **강제 통과**(사유 로그됨)
- 파일 없음 → **통과**(미강제 = 한계 §0)

`task:` 줄은 사람이 읽기용. 게이트는 체크박스 상태만 본다.
새 산출물 작업 시작 시 contract.md를 **새 내용으로 덮어쓴다**(이전 task 잔재 제거).

---

## 3. completion_gate.sh (Stop, 교체)

의존성: bash + grep + sha1sum(git-bash 기본). Date 미사용.

**의사코드**
```bash
INPUT = stdin                          # Stop 훅 payload (JSON)
cwd   = extract "cwd" from INPUT        # session_start_context.sh와 동일 방식
state_dir = (writable {cwd}/.claude/state) ? 그것 : ~/.claude/state
contract  = state_dir/contract.md
counter   = state_dir/.gate_count       # "sig count" 한 줄
ovlog     = state_dir/.gate_override.log

# stop_hook_active 무시한다 — 우리 백스톱 카운터로 루프 안전 보장(아래)

if [ ! -f contract ]; then exit 0; fi            # 활성 계약 없음 → 통과

unchecked = grep -c '^[[:space:]]*- \[ \]' contract
if [ unchecked -eq 0 ]; then
    rm -f counter; exit 0                          # 전부 [x]/[~] → 통과(카운터 리셋)
fi

if grep -q '^[[:space:]]*OVERRIDE:' contract; then  # 전체 강제 통과
    echo "[gate-override] $(grep '^[[:space:]]*OVERRIDE:' contract)" >> ovlog
    rm -f counter; exit 0
fi

# --- 여기부터 미체크 존재: 차단 후보 ---
sig = sha1sum(contract) | cut field1
read prev_sig prev_cnt < counter (없으면 "", 0)
cnt = (sig == prev_sig) ? prev_cnt+1 : 1          # 진행 있으면(내용변경) 리셋
echo "sig cnt" > counter

N = 3
if [ cnt -ge N ]; then
    # 백스톱: 무진행 N회 → 경고 로그 남기고 자동통과
    echo "[gate-backstop] auto-pass, unchecked items:" >> ovlog
    grep '^[[:space:]]*- \[ \]' contract >> ovlog
    rm -f counter
    # additionalContext로 경고(에러톤 아님)
    cat <<JSON
{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"⚠ 게이트 백스톱: 미체크 항목이 남았지만 N회 무진행으로 자동통과함. 미완 항목을 사용자에게 명시 보고할 것."}}
JSON
    exit 0
fi

# 차단
unchecked_list = grep '^[[:space:]]*- \[ \]' contract
emit decision:block, reason =
  "종료 차단(강경 게이트). contract.md 미체크 항목:\n<unchecked_list>\n
   완료면 [x], 의도적 축소면 [~]사유, 전체포기면 OVERRIDE:사유 로 바꿔라.
   ({cnt}/{N}회 — N회 무진행 시 경고 남기고 자동통과)"
exit 0
```

**핵심 포인트**
- `stop_hook_active` 가드를 **쓰지 않는다**(현재 gate와 다름). 대신 sha1 카운터로 "무진행 N회 → 자동통과" 백스톱이 종료를 보장 → 무한루프 불가.
- 카운터는 **contract 내용이 바뀌면 리셋** → 한 칸이라도 체크하면(=진행) 다시 N번 기회. 진짜 갇힘(0 진행)일 때만 백스톱 발동.
- 차단 사유에 **미체크 항목 목록 + 탈출 문법 + 현재 카운트**를 넣어 내가 바로 대응 가능.

---

## 4. completion_discipline.sh (UserPromptSubmit, 개조)

현재: 매 턴 완료규율 텍스트 주입. 개조: **짧게** + contract 경로 안내 + B형 항목.

**주입 문안(안)**
```
[완료 규율 — 산출물 작업에만]
산출물 작업이면 착수 전 {state_dir}/contract.md 에 done을 "- [ ] 셀 수 있는 항목"으로 선언.
코딩작업이면 "- [ ] 2+ 케이스로 검증(ripple-search)" 항목 필수 포함.
종료는 모든 항목 [x](완료)/[~]사유(축소)일 때만 통과(강경 Stop 게이트).
잡담·자명한 단일수정은 무시.
```
- `{state_dir}`는 스크립트가 cwd로 계산해 실제 경로를 넣어준다(내가 바로 그 경로에 쓰게).
- 현재보다 짧게 → 희석 완화. 운영 상세는 CLAUDE.md에서 뺀다(§7).
- "산출물 작업이면"은 내 판단(휴리스틱) — 한계 §0.
- 항상 exit 0(fail-open).

---

## 5. literal_lint.py (PostToolUse: Write|Edit, 신규)

입력: PostToolUse payload. `tool_input.content`(Write) 또는 `tool_input.new_string`(Edit)에서 **추가 텍스트**를 스캔.

**파일 필터(스캔 대상만)**
- 대상 확장자: `.py .js .ts .tsx .jsx .go .rs .java .rb .php .c .cpp .sh`
- 제외 경로: `/test`, `/tests`, `/__tests__`, `/.claude`, `/config`, `/migrations`, `/fixtures`
- 제외 확장자: `.yaml .yml .json .md .lock .txt .csv`

**패턴(주석 제거 후 라인 단위)**
| 종류      | 정규식                                           | 의미                   |                        |
| --------- | ------------------------------------------------ | ---------------------- | ---------------------- |
| 연도      | `\b(?:19                                         | 20)\d{2}\b`            | 분석연도 하드코딩 의심 |
| 긴 식별자 | `\b\d{6,}\b`                                     | corp_code 등 ID 리터럴 |                        |
| 거대 상수 | `\b\d{7,}\b` 또는 `\b\d+(?:_\d+)*e\d+\b`(지수≥6) | 절대 임계 하드코딩     |                        |

- 주석 제거: 라인에서 첫 `#`(py/sh) 또는 `//`(c계열) 이후 잘라냄.
- 문자열 내부도 일단 잡되, false positive는 경고라 허용(차단 아님).

**출력**
- 히트 없으면 그냥 exit 0(무출력).
- 히트 있으면 stdout(=additionalContext)에:
```
⚠ 리터럴 점검(§3): {file}
  L?: <매치된 리터럴> (<종류>)
이 값이 계산을 구동(분기·임계·대상선정)하면 데이터·인자·config로 빼라. 단순 상수면 무시.
```
- **절대 차단 안 함**(decision:block 미사용). exit 0 고정.
- 무의존(표준 라이브러리만), 빠르게.

**프로젝트별 off 스위치**: `{cwd}/.claude/state/.nolint` 파일 있으면 즉시 exit 0(거대숫자 정상 프로젝트 대비).

---

## 6. settings.json 변경 (diff)

기존 훅 전부 보존. **literal_lint만 추가**.

```jsonc
"PostToolUse": [
  { "matcher": "Write|Edit", "hooks": [
      { "type": "command", "command": "python /c/Users/ghdtj/.claude/hooks/post_write_check.py" },
      { "type": "command", "command": "python /c/Users/ghdtj/.claude/hooks/literal_lint.py" }   // ← 추가
  ]}
]
```
- `completion_gate.sh`·`completion_discipline.sh`는 경로 그대로(스크립트 내용만 교체) → settings 변경 불필요.
- 나머지 훅(guard_bash, post_write_check, session_start_context, work-summary-*) 손대지 않음.

---

## 7. CLAUDE.md 다이어트 (중복 제거)

원칙은 CLAUDE.md, 운영 강제는 훅. 중복 prose를 훅으로 이관.

| 섹션           | 현재                                   | 변경                                                                                                 |
| -------------- | -------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| §3 범용해결    | 구동값 입력 원칙 + 예시 다수           | **원칙 유지**(린트가 참조), 예시 1개로 축약                                                          |
| §9 성급한 종료 | 긴 운영 prose(hollow-PASS·baseline 등) | 원칙 2~3줄로 압축 + "운영 강제는 contract 게이트" 포인터                                             |
| §10 전수 측정  | 6개 운영 불릿                          | 원칙(전수 기본·done=셀수있는항목·도구경계≠감사경계) 3줄, "sub-ask 체크리스트 강제"는 contract로 이관 |

목표: 핵심 규칙 주의력 회복(긴 운영문구 → 훅이 매 턴/종료에 주입하므로 CLAUDE.md 중복 불필요).
※ 한글 인코딩 가드(§4): 최소 edit만, mojibake 검증 후 완료.

---

## 8. 파일/디렉터리 일람

```
신규:
  ~/.claude/hooks/literal_lint.py            리터럴 경고
  {cwd}/.claude/state/                        contract·counter·log (프로젝트별)
  {cwd}/.claude/state/contract.md             활성 task 계약
  {cwd}/.claude/state/.gate_count             백스톱 카운터 "sig count"
  {cwd}/.claude/state/.gate_override.log       override·backstop 기록
  {cwd}/.claude/.gitignore                     state/ 무시(또는 프로젝트 gitignore에 추가)
교체:
  ~/.claude/hooks/completion_gate.sh          contract 파서 + 백스톱
  ~/.claude/hooks/completion_discipline.sh    contract 작성 지시
수정:
  ~/.claude/settings.json                     literal_lint 등록
  ~/.claude/CLAUDE.md                          §3·§9·§10 다이어트
```

`.gitignore` 항목: `.claude/state/`

---

## 9. 테스트 계획 (pipe-test, 구현 후 즉시)

각 훅에 가짜 stdin 주입해 기대 동작 확인.

| #   | 대상       | 입력                                       | 기대                                                |
| --- | ---------- | ------------------------------------------ | --------------------------------------------------- |
| T1  | gate       | contract 없음                              | exit0, 무출력(통과)                                 |
| T2  | gate       | `- [ ]` 1개 포함 contract                  | decision:block, 미체크 목록 출력, .gate_count=1     |
| T3  | gate       | T2 직후 동일 contract 재입력 ×2            | 2회차 block(cnt2), 3회차 자동통과+override.log 기록 |
| T4  | gate       | 모든 항목 `[x]`                            | exit0 통과, counter 삭제                            |
| T5  | gate       | `[~]사유`만 남음                           | exit0 통과                                          |
| T6  | gate       | `OVERRIDE: 사유` 포함                      | exit0 통과, override.log 기록                       |
| T7  | gate       | block 후 한 칸 [x]로 변경(내용변경) 재입력 | counter 리셋(cnt1), 남은 [ ]면 block                |
| T8  | discipline | 임의 prompt                                | 짧은 규율+실제 state 경로 주입, exit0               |
| T9  | lint       | `year=2019` 든 .py content                 | 경고 출력, exit0(차단 아님)                         |
| T10 | lint       | `port=8080`.py 인데 `.nolint` 존재         | 무출력 exit0                                        |
| T11 | lint       | `config/x.yaml`에 `100000000`              | 무출력(제외 경로)                                   |
| T12 | lint       | 주석 `# corp 00126380`                     | 무출력(주석 제외)                                   |

---

## 10. 구현 순서 + 롤백

**순서**: (1) state 디렉터리·contract 템플릿·.gitignore → (2) completion_gate.sh 교체 → T1~T7 → (3) completion_discipline.sh 교체 → T8 → (4) literal_lint.py → T9~T12 → (5) settings.json 등록 → (6) CLAUDE.md 다이어트.

**롤백**: 각 교체 전 원본 `.bak` 보존(guard_bash.sh.bak 선례). 문제 시 .bak 복원 + settings에서 literal_lint 줄 제거로 즉시 원복.

**N 기본값**: 3. 구현 후 체감으로 조정(스크립트 상단 상수).
