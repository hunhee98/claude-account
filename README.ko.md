# claude-account

[![macOS](https://img.shields.io/badge/macOS-zsh-blue?style=flat-square)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)](LICENSE)

[Claude Code](https://github.com/anthropics/claude-code)에서 여러 계정을 쓰고 계신가요?

계정을 쉽게 바꾸고, 프로젝트마다 계정을 다르게 설정할 수 있어요.
매번 로그인할 필요 없이, 설정된 계정이 알아서 적용돼요.

**[English](README.md)**

<!-- TODO: 실제 gif로 교체 -->
<!-- ![demo](demo.gif) -->

## 시작하기

**1단계.** claude-account를 설치해 주세요.

**Homebrew (권장):**
```bash
brew tap hunhee98/claude-account
brew install claude-account
```

**직접 설치:**
```bash
git clone https://github.com/hunhee98/claude-account.git
cd claude-account && ./install.sh
```

**2단계.** 현재 쉘에 반영해 주세요.

```bash
source ~/.zshrc
```

**3단계.** 이제 `claude account`로 계정을 전환할 수 있어요.

## 사용법

```bash
claude account            # 기본 계정 전환 (목록에서 골라요)
claude account add        # 새 계정을 추가해요
claude account delete     # 저장된 계정을 삭제해요
claude account pin        # 이 프로젝트에 계정을 고정해요
claude account status     # 지금 어떤 계정인지 확인해요
```

`account` 외의 명령어는 원래 `claude`에 그대로 전달돼요.

### 프로젝트에 계정 고정하기

```bash
cd ~/work/my-project
claude account pin        # 고정할 계정을 골라 주세요
```

프로젝트 경로가 `~/.claude-accounts/.pins/`에 저장돼요.
프로젝트 폴더 안에는 아무 파일도 생기지 않아요.
이후 이 프로젝트 안에서 `claude`를 실행하면, 고정한 계정이 자동으로 쓰여요.
전역 기본 계정과는 상관없어요.

## 이렇게 동작해요

`claude-account`는 `claude` CLI를 가볍게 감싸는 쉘 함수예요.
실행할 때 `$HOME`을 계정 전용 디렉토리로 바꿔서, 계정마다 인증 정보를 완전히 분리해요.

```
~/.claude-accounts/
  personal/          # "personal" 계정의 인증 정보
  work/              # "work" 계정의 인증 정보
  .current           # 지금 기본으로 쓰는 계정
  .pins/work         # "work"에 고정된 프로젝트 경로

~/.claude-homes/
  personal/.claude → ~/.claude-accounts/personal  (심볼릭 링크)
  work/.claude     → ~/.claude-accounts/work      (심볼릭 링크)
```

`claude`를 실행하면 이런 순서로 동작해요.

1. 현재 디렉토리부터 위로 올라가며 `.claude-account` 파일을 찾아요
2. 없으면 `~/.claude-accounts/.current`에 저장된 기본 계정을 써요
3. 해당 계정 디렉토리로 `HOME`을 설정한 뒤 `claude`를 실행해요

## 이것만은 알아두세요

`claude-account`는 인증 정보 관리만 담당해요. 어떤 계정으로 실행할지 결정해줄 뿐, Claude Code 실행 이후의 동작 범위(파일 접근, 사용 가능한 도구 등)는 건드리지 않아요.

예를 들어 회사 계정으로만 접근해야 하는 경로나 도구가 있다면, 개인 계정이 그 영역을 침범하지 못하도록 직접 제한을 걸어야 해요. 그 부분은 Claude Code 자체 기능으로 설정해주세요.

- **프로젝트별 규칙:** 프로젝트 루트에 `CLAUDE.md` 또는 `.claude/settings.json` 추가
- **도구 허용/차단:** 설정의 `allowedTools` / `disabledTools` 필드 활용

계정을 올바르게 불러오는 건 `claude-account`가 해줄게요. 그 계정으로 무엇을 허용할지는 Claude Code 설정에서 직접 정해주세요.

## 필요한 것

- macOS (zsh)
- [Claude Code CLI](https://github.com/anthropics/claude-code)
- [gum](https://github.com/charmbracelet/gum) — 없으면 알아서 설치돼요

## 제거하기

```bash
# Homebrew
brew uninstall claude-account

# 직접 설치한 경우
sed -i '' '/^# claude-account$/,+1d' ~/.zshrc
rm -f ~/.claude-account.sh

# 저장된 계정 데이터까지 지우고 싶다면
rm -rf ~/.claude-accounts ~/.claude-homes
```

## 라이선스

MIT
