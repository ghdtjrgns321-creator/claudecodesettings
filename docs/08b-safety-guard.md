# 08b. 안전 가드 하네스 (guard_bash)

> 위험한 셸 명령을 **실행 전에** 차단. PreToolUse:Bash 이벤트에서 `exit 2`로 차단.
> ← [08. 하네스 개요](08-harness.md)

## 원리

- Claude가 Bash 도구를 호출하면, 실행되기 **전에** `guard_bash.sh`가 명령을 검사
- 위험 패턴이면 `exit 2`(차단) + stderr로 사유를 Claude에 전달 → 명령이 실행되지 않는다.
- PowerShell 대소문자 무시(`nocasematch`)로 PS 변형도 잡는다.

## 차단하는 것

| 분류            | 차단 패턴                                                                                                                            |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| **파일 파괴**   | `rm -rf /` · `rm -rf ~` · `chmod 777` · PowerShell `Remove-Item -Recurse -Force`(및 alias `ri`) · cmd `rmdir /s /q`                  |
| **원격 실행**   | `curl … \| sh` / `\| bash` (신뢰 못 할 원격 스크립트 파이프)                                                                         |
| **위험한 Git**  | 보호 브랜치(main·master·develop)에 `push --force` · `reset --hard origin/보호브랜치`                                                 |
| **시크릿 접근** | `.env`·`credentials.json`·`.ssh/`·`.netrc` 를 `cat/less/head/tail` 또는 PS `Get-Content/gc/type`로 읽기                              |
| **시크릿 노출** | `echo`/`printf`로 `$API_KEY`·`$SECRET`·`$TOKEN`·`$PASSWORD`·`$env:*KEY` 출력                                                         |
| **전역 설치**   | `npm install -g` · `pip install --user`/`--break-system-packages` · `cargo install --git` · `uv tool install` (터미널에서 직접 하라) |
| **폴링 루프**   | `until/while … grep/test … sleep … do` (백그라운드 작업은 완료 알림을 기다려라 — 폴링은 헛돈다)                                      |

## 훅 사용

- `.env` 읽기는 `settings.json`의 `permissions.deny`로도 막지만, **셸 우회**(`cat .env`)는 permission을 안 탄다 → guard_bash가 그 구멍을 막는다.
- "위험 명령 하지 마"라고 CLAUDE.md에 쓰는 건 ~80%만 지켜진다. 훅은 **100% 결정적**.

## 한계

- 정규식 기반이라 우회 변형(난독화 명령)은 놓칠 수 있다 — 방어 심화(defense-in-depth)의 한 겹이지 완전 차단은 아니다.
- 정상 명령 오차단 시 사유가 stderr로 오므로 즉시 인지·수정 가능.
