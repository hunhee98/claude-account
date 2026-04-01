#!/usr/bin/env zsh
# claude-account — per-project & global account isolation for Claude Code CLI

# ── 상수 ─────────────────────────────────────────────────────────────────────
_CSW_ACCOUNTS="${HOME}/.claude-accounts"
_CSW_HOMES="${HOME}/.claude-homes"
_CSW_CURRENT="${_CSW_ACCOUNTS}/.current"

# ── 언어 감지 & 메시지 ────────────────────────────────────────────────────────
if [[ "${LANG:-${LC_ALL:-}}" == ko* ]]; then
  _CSW_LANG="ko"
else
  _CSW_LANG="en"
fi

_csw_msg() {
  local key="${1}"
  shift
  local -A ko=(
    [default_account]="기본 계정"
    [project_account]="이 프로젝트"
    [none]="없음"
    [no_accounts]="저장된 계정이 없습니다."
    [no_accounts_hint]="먼저 claude account add 로 계정을 추가하세요."
    [select_default]="기본 계정 선택"
    [select_delete]="삭제할 계정 선택"
    [select_pin]="고정할 계정 선택"
    [switched]="기본 계정 →"
    [switched_note]="실행 중인 세션은 영향 없음. 새 claude 실행 시 적용됩니다."
    [already_default]="은(는) 이미 기본 계정입니다."
    [pinned]="계정으로 고정했습니다. → .claude-account"
    [add_title]="새 계정 추가"
    [add_desc]="빈 환경으로 claude를 실행합니다. 브라우저에서 새 계정으로 로그인하세요."
    [add_running]="▶ claude 실행 중... (브라우저에서 새 계정으로 로그인하세요)"
    [add_name_prompt]="저장할 계정 이름: "
    [add_name_empty]="이름을 입력하세요."
    [add_name_invalid]="이름에 '/' 또는 '\\'는 사용할 수 없습니다."
    [add_overwrite]="계정이 이미 존재합니다. 덮어쓰시겠습니까? (y/N): "
    [add_overwrite_retry]="다른 이름을 입력하세요."
    [add_done]="계정 저장 완료!"
    [add_login_fail]="오류: 로그인이 완료되지 않은 것 같습니다."
    [delete_no_deletable]="삭제 가능한 계정이 없습니다. (기본 계정은 삭제 불가)"
    [delete_default_excluded]="기본 계정 삭제 불가 (목록에서 제외됨)"
    [delete_confirm]="'%s' 계정을 삭제하시겠습니까? (y/N): "
    [delete_done]="계정이 삭제되었습니다."
    [cancelled]="취소되었습니다."
    [warn_not_found]="경고: '%s' 계정을 찾을 수 없습니다. 기본값으로 실행합니다."
    [warn_not_saved]="경고: '%s' 계정이 저장되어 있지 않습니다."
    [err_not_found]="오류: '%s' 계정이 존재하지 않습니다."
    [project_label]="프로젝트"
    [current_pin]="현재 고정"
    [pinned_projects]="고정된 프로젝트"
    [account_list]="계정 목록"
    [pinned_label]="pin"
    [help_title]="사용법: claude account [add|delete|pin|status]"
    [help_account]="  claude account         계정 목록 및 전환"
    [help_add]="  claude account add     새 계정 추가"
    [help_delete]="  claude account delete  계정 삭제"
    [help_pin]="  claude account pin     이 프로젝트에 계정 고정"
    [help_status]="  claude account status  현재 계정 확인"
    [dep_missing]="gum이 설치되어 있지 않습니다. 자동 설치를 시작합니다..."
    [dep_no_brew]="Homebrew가 없습니다. 먼저 Homebrew를 설치하세요."
    [dep_fail]="gum 설치 실패. 수동으로 설치하세요: brew install gum"
  )
  local -A en=(
    [default_account]="Default account"
    [project_account]="This project"
    [none]="none"
    [no_accounts]="No saved accounts."
    [no_accounts_hint]="Run claude account add to add one."
    [select_default]="Select default account"
    [select_delete]="Select account to delete"
    [select_pin]="Select account to pin"
    [switched]="Default account →"
    [switched_note]="Running sessions are not affected. Takes effect on next claude launch."
    [already_default]="is already the default account."
    [pinned]="account pinned. → .claude-account"
    [add_title]="Add new account"
    [add_desc]="Claude will launch in a clean environment. Log in with a new account in the browser."
    [add_running]="▶ Launching claude... (log in with your new account in the browser)"
    [add_name_prompt]="Account name to save: "
    [add_name_empty]="Please enter a name."
    [add_name_invalid]="Name cannot contain '/' or '\\'."
    [add_overwrite]="Account already exists. Overwrite? (y/N): "
    [add_overwrite_retry]="Please enter a different name."
    [add_done]="Account saved."
    [add_login_fail]="Error: Login does not appear to have completed."
    [delete_no_deletable]="No deletable accounts. (Default account cannot be deleted)"
    [delete_default_excluded]="Default account excluded from list"
    [delete_confirm]="Delete account '%s'? (y/N): "
    [delete_done]="Account deleted."
    [cancelled]="Cancelled."
    [warn_not_found]="Warning: account '%s' not found. Running with default."
    [warn_not_saved]="Warning: account '%s' is not saved."
    [err_not_found]="Error: account '%s' does not exist."
    [project_label]="Project"
    [current_pin]="Current pin"
    [pinned_projects]="Pinned projects"
    [account_list]="Accounts"
    [pinned_label]="pin"
    [help_title]="Usage: claude account [add|delete|pin|status]"
    [help_account]="  claude account         Account list & switch"
    [help_add]="  claude account add     Add new account"
    [help_delete]="  claude account delete  Delete account"
    [help_pin]="  claude account pin     Pin account to this project"
    [help_status]="  claude account status  Show current account"
    [dep_missing]="gum is not installed. Installing automatically..."
    [dep_no_brew]="Homebrew is not installed. Please install it first."
    [dep_fail]="gum installation failed. Install manually: brew install gum"
  )

  local msg
  if [[ "${_CSW_LANG}" == "ko" ]]; then
    msg="${ko[$key]}"
  else
    msg="${en[$key]}"
  fi

  if [[ $# -gt 0 ]]; then
    printf "${msg}\n" "$@"
  else
    echo "${msg}"
  fi
}

# ── 의존성 ────────────────────────────────────────────────────────────────────
_csw_ensure_gum() {
  command -v gum &>/dev/null && return 0

  _csw_msg dep_missing
  if ! command -v brew &>/dev/null; then
    _csw_msg dep_no_brew >&2
    return 1
  fi

  brew install gum || { _csw_msg dep_fail >&2; return 1; }
}

# ── 내부 유틸 ─────────────────────────────────────────────────────────────────
_csw_ensure_dirs() {
  mkdir -p "${_CSW_ACCOUNTS}"
  mkdir -p "${_CSW_HOMES}"
}

_csw_current() {
  [[ -f "${_CSW_CURRENT}" ]] && cat "${_CSW_CURRENT}" || echo ""
}

_csw_list_accounts() {
  find "${_CSW_ACCOUNTS}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | grep -v '^\.' | sort
}

_csw_account_exists() {
  [[ -d "${_CSW_ACCOUNTS}/${1}" ]]
}

_csw_make_stub() {
  local name="${1}"
  local stub="${_CSW_HOMES}/${name}"
  mkdir -p "${stub}"
  if [[ ! -L "${stub}/.claude" ]] || [[ ! -e "${stub}/.claude" ]]; then
    ln -sf "${_CSW_ACCOUNTS}/${name}" "${stub}/.claude"
  fi
  if [[ ! -L "${stub}/.claude.json" ]] || [[ ! -e "${stub}/.claude.json" ]]; then
    ln -sf "${_CSW_ACCOUNTS}/${name}/.claude.json" "${stub}/.claude.json"
  fi
  if [[ ! -L "${stub}/Library" ]] || [[ ! -e "${stub}/Library" ]]; then
    ln -sf "${HOME}/Library" "${stub}/Library"
  fi
}

_csw_account_email() {
  local json="${_CSW_ACCOUNTS}/${1}/.claude.json"
  [[ -f "${json}" ]] || return
  grep -o '"emailAddress": *"[^"]*"' "${json}" 2>/dev/null | head -1 | sed 's/.*": *"//' | sed 's/"$//'
}

_csw_find_project_account() {
  local current_dir="${PWD}"
  local pins_dir="${_CSW_ACCOUNTS}/.pins"
  [[ ! -d "${pins_dir}" ]] && return 1

  local acc path
  for acc in "${pins_dir}"/*; do
    [[ ! -f "${acc}" ]] && continue
    while IFS= read -r path; do
      [[ -z "${path}" ]] && continue
      if [[ "${current_dir}" == "${path}" ]] || [[ "${current_dir}" == "${path}"/* ]]; then
        echo "${acc##*/}"
        return 0
      fi
    done < "${acc}"
  done
  return 1
}

# ── gum 선택 헬퍼 ────────────────────────────────────────────────────────────
# _csw_pick <header> < <(account list)
# 선택된 항목을 stdout 으로 출력. 취소(Esc/Ctrl+C) 시 빈 문자열.
_csw_pick() {
  local header="${1}"
  gum choose \
    --header="${header}" \
    --height=10 \
    --cursor="▶ " \
    --cursor.foreground="12" \
    --header.foreground="8"
}

# ── 계정 관리 서브커맨드 ──────────────────────────────────────────────────────

_csw_cmd_account() {
  _csw_ensure_dirs
  _csw_ensure_gum || return 1

  local current
  current=$(_csw_current)

  local project_account
  project_account=$(_csw_find_project_account 2>/dev/null)

  local -a accounts=()
  while IFS= read -r line; do
    accounts+=("${line}")
  done < <(_csw_list_accounts)

  if [[ ${#accounts[@]} -eq 0 ]]; then
    _csw_msg no_accounts
    _csw_msg no_accounts_hint
    return 1
  fi

  # 현재 기본 계정에 마커 추가
  local -a display=()
  local acc
  for acc in "${accounts[@]}"; do
    if [[ "${acc}" == "${current}" ]]; then
      display+=("${acc}  ✓")
    else
      display+=("${acc}")
    fi
  done

  local header
  header="$(_csw_msg select_default)"

  local selected
  selected=$(printf '%s\n' "${display[@]}" | _csw_pick "${header}")
  [[ -z "${selected}" ]] && return 0

  # 마커 제거 후 전환
  _csw_switch_global "${selected%  ✓}"
}

_csw_switch_global() {
  local name="${1}"

  if ! _csw_account_exists "${name}"; then
    _csw_msg err_not_found "${name}" >&2
    return 1
  fi

  if [[ "${name}" == "$(_csw_current)" ]]; then
    printf "[claude account] '${name}' $(_csw_msg already_default)\n"
    return 0
  fi

  echo "${name}" > "${_CSW_CURRENT}"
  printf "[claude account] $(_csw_msg switched) '\033[1m%s\033[0m'\n" "${name}"
  printf "\033[2m  $(_csw_msg switched_note)\033[0m\n"
}

_csw_cmd_pin() {
  _csw_ensure_dirs
  _csw_ensure_gum || return 1

  local -a accounts=()
  while IFS= read -r line; do
    accounts+=("${line}")
  done < <(_csw_list_accounts)

  if [[ ${#accounts[@]} -eq 0 ]]; then
    _csw_msg no_accounts
    _csw_msg no_accounts_hint
    return 1
  fi

  local header
  header="$(_csw_msg select_pin)"

  local selected
  selected=$(printf '%s\n' "${accounts[@]}" | _csw_pick "${header}")
  [[ -z "${selected}" ]] && return 0

  # 중앙 레지스트리에만 경로 등록 (중복 방지)
  local pins_file="${_CSW_ACCOUNTS}/.pins/${selected}"
  mkdir -p "${_CSW_ACCOUNTS}/.pins"
  grep -qxF "${PWD}" "${pins_file}" 2>/dev/null || echo "${PWD}" >> "${pins_file}"

  printf "[claude account] '\033[1m%s\033[0m' $(_csw_msg pinned)\n" "${selected}"
}

_csw_cmd_add() {
  echo ""
  printf "\033[1m[claude account] $(_csw_msg add_title)\033[0m\n"
  echo ""

  # 1. 계정 이름 먼저 받기
  local name
  while true; do
    printf "$(_csw_msg add_name_prompt)"
    read -r name
    name="${name//[[:space:]]/}"

    [[ -z "${name}" ]]       && { _csw_msg add_name_empty;   continue; }
    [[ "${name}" =~ [/\\] ]] && { _csw_msg add_name_invalid; continue; }

    if _csw_account_exists "${name}"; then
      printf "$(_csw_msg add_overwrite)"
      read -r ow
      [[ "${ow}" =~ ^[Yy]$ ]] || { _csw_msg add_overwrite_retry; continue; }
    fi

    break
  done

  # 2. 로그인
  echo ""
  _csw_msg add_desc
  echo ""
  _csw_msg add_running

  local tmp_home
  tmp_home=$(mktemp -d)
  mkdir -p "${tmp_home}/.claude"
  HOME="${tmp_home}" command claude

  if [[ -z "$(ls -A "${tmp_home}/.claude" 2>/dev/null)" ]]; then
    rm -rf "${tmp_home}"
    _csw_msg add_login_fail >&2
    return 1
  fi

  # 3. 저장
  rm -rf "${_CSW_ACCOUNTS}/${name}"
  cp -r "${tmp_home}/.claude" "${_CSW_ACCOUNTS}/${name}"
  [[ -f "${tmp_home}/.claude.json" ]] && cp "${tmp_home}/.claude.json" "${_CSW_ACCOUNTS}/${name}/.claude.json"
  rm -rf "${tmp_home}"
  _csw_make_stub "${name}"

  echo "${name}" > "${_CSW_CURRENT}"

  local email
  email=$(_csw_account_email "${name}")
  echo ""
  printf "[claude account] $(_csw_msg add_done)\n"
  if [[ -n "${email}" ]]; then
    printf "  \033[1m%s\033[0m  \033[2m(%s)\033[0m\n" "${name}" "${email}"
  else
    printf "  \033[1m%s\033[0m\n" "${name}"
  fi
}

_csw_cmd_delete() {
  _csw_ensure_dirs
  _csw_ensure_gum || return 1

  local current
  current=$(_csw_current)

  local -a deletable=()
  local acc
  while IFS= read -r acc; do
    [[ "${acc}" != "${current}" ]] && deletable+=("${acc}")
  done < <(_csw_list_accounts)

  if [[ ${#deletable[@]} -eq 0 ]]; then
    _csw_msg delete_no_deletable
    return 1
  fi

  local header
  header="$(_csw_msg select_delete)"

  local selected
  selected=$(printf '%s\n' "${deletable[@]}" | _csw_pick "${header}")
  [[ -z "${selected}" ]] && return 0

  printf "$(printf "$(_csw_msg delete_confirm)" "${selected}")"
  read -r confirm

  if [[ "${confirm}" =~ ^[Yy]$ ]]; then
    rm -rf "${_CSW_ACCOUNTS}/${selected}"
    rm -rf "${_CSW_HOMES}/${selected}"
    rm -f "${_CSW_ACCOUNTS}/.pins/${selected}"
    printf "[claude account] '\033[1m%s\033[0m' $(_csw_msg delete_done)\n" "${selected}"
  else
    _csw_msg cancelled
  fi
}

_csw_cmd_status() {
  _csw_ensure_dirs
  local current
  current=$(_csw_current)

  printf "$(_csw_msg default_account): \033[1m%s\033[0m\n" "${current:-$(_csw_msg none)}"

  local project_account
  project_account=$(_csw_find_project_account 2>/dev/null)
  if [[ -n "${project_account}" ]]; then
    printf "$(_csw_msg project_account): \033[36m%s\033[0m\n" "${project_account}"
    _csw_account_exists "${project_account}" || \
      printf "$(_csw_msg warn_not_saved)\n" "${project_account}"
  fi

  # 계정별 핀된 프로젝트 목록
  local -a accounts=()
  while IFS= read -r line; do
    accounts+=("${line}")
  done < <(_csw_list_accounts)

  [[ ${#accounts[@]} -eq 0 ]] && return

  echo ""
  printf "\033[2m$(_csw_msg account_list)\033[0m\n"
  local acc email label
  for acc in "${accounts[@]}"; do
    email=$(_csw_account_email "${acc}")
    label=""
    [[ -n "${email}" ]] && label="  \033[2m${email}\033[0m"

    if [[ "${acc}" == "${current}" ]]; then
      printf "  \033[1m%s\033[0m%b\n" "${acc}" "${label}"
    else
      printf "  \033[2m%s\033[0m%b\n" "${acc}" "${label}"
    fi

    local pins_file="${_CSW_ACCOUNTS}/.pins/${acc}"
    [[ -f "${pins_file}" ]] || continue

    local -a valid_paths=()
    local path
    while IFS= read -r path; do
      [[ -z "${path}" ]] && continue
      [[ -d "${path}" ]] && valid_paths+=("${path}")
    done < "${pins_file}"

    [[ ${#valid_paths[@]} -eq 0 ]] && continue

    printf "    \033[2m[pinned]\033[0m\n"
    for path in "${valid_paths[@]}"; do
      printf "    \033[2m→\033[0m  %s\n" "${path}"
    done
  done
}

# ── claude 래퍼 (진입점) ──────────────────────────────────────────────────────
claude() {
  _csw_ensure_dirs

  if [[ "${1}" == "--help" || "${1}" == "-h" ]]; then
    command claude "$@"
    printf "  %-50s%s\n" "account"        "Switch between saved accounts"
    printf "  %-50s%s\n" "account add"    "Log in and save a new account"
    printf "  %-50s%s\n" "account delete" "Remove a saved account"
    printf "  %-50s%s\n" "account pin"    "Pin an account to the current project"
    printf "  %-50s%s\n" "account status" "Show the active account"
    return
  fi

  if [[ "${1}" == "account" ]]; then
    case "${2}" in
      add)    _csw_cmd_add ;;
      delete) _csw_cmd_delete ;;
      pin)    _csw_cmd_pin ;;
      status) _csw_cmd_status ;;
      "")     _csw_cmd_account ;;
      *)
        _csw_msg help_title
        echo ""
        _csw_msg help_account
        _csw_msg help_add
        _csw_msg help_delete
        _csw_msg help_pin
        _csw_msg help_status
        ;;
    esac
    return
  fi

  # 일반 실행 → 프로젝트 고정 계정 or 전역 기본 계정으로 HOME 오버라이드
  local account
  account=$(_csw_find_project_account 2>/dev/null)
  [[ -z "${account}" ]] && account=$(_csw_current)

  if [[ -n "${account}" ]]; then
    local stub="${_CSW_HOMES}/${account}"

    if [[ ! -d "${stub}" ]]; then
      if _csw_account_exists "${account}"; then
        _csw_make_stub "${account}"
      else
        printf "[claude account] $(_csw_msg warn_not_found)\n" "${account}" >&2
        command claude "$@"
        return
      fi
    fi

    HOME="${stub}" command claude "$@"
  else
    command claude "$@"
  fi
}
