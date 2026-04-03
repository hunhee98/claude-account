#!/usr/bin/env zsh
# claude-account — per-project & global account isolation for Claude Code CLI

# ── 상수 ─────────────────────────────────────────────────────────────────────
_CSW_REAL_HOME="${HOME}"
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
    [pinned]="계정으로 고정했습니다."
    [add_title]="새 계정 추가"
    [add_desc]="빈 환경으로 claude를 실행합니다. 브라우저에서 새 계정으로 로그인하세요."
    [add_running]="▶ claude 실행 중... (브라우저에서 새 계정으로 로그인하세요)"
    [add_name_prompt]="저장할 계정 이름: "
    [add_name_empty]="이름을 입력하세요."
    [add_name_invalid]="이름에 '/' 또는 '\\'는 사용할 수 없습니다."
    [add_overwrite]="계정이 이미 존재합니다. 덮어쓰시겠습니까? (y/N): "
    [add_overwrite_retry]="다른 이름을 입력하세요."
    [add_done]="계정 저장 완료!"
    [setup_zshrc]="~/.zshrc에 다음을 추가하세요:"
    [setup_reload]="그 후 실행:"
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
    [pinned_label]="고정"
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
    [pinned]="account pinned."
    [add_title]="Add new account"
    [add_desc]="Claude will launch in a clean environment. Log in with a new account in the browser."
    [add_running]="▶ Launching claude... (log in with your new account in the browser)"
    [add_name_prompt]="Account name to save: "
    [add_name_empty]="Please enter a name."
    [add_name_invalid]="Name cannot contain '/' or '\\'."
    [add_overwrite]="Account already exists. Overwrite? (y/N): "
    [add_overwrite_retry]="Please enter a different name."
    [add_done]="Account saved."
    [setup_zshrc]="Add the following to ~/.zshrc:"
    [setup_reload]="Then run:"
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

  # 진짜 HOME의 모든 dotfile/디렉토리를 심볼릭 링크 (.claude, .claude.json 제외)
  local item base
  for item in "${_CSW_REAL_HOME}"/.[!.]*(N) "${_CSW_REAL_HOME}"/..?*(N); do
    [[ ! -e "${item}" ]] && continue
    base="${item##*/}"
    [[ "${base}" == ".claude" || "${base}" == ".claude.json" ]] && continue
    [[ -e "${stub}/${base}" ]] && continue
    ln -sf "${item}" "${stub}/${base}"
  done

  # Library (macOS)
  [[ -d "${_CSW_REAL_HOME}/Library" && ! -e "${stub}/Library" ]] && \
    ln -sf "${_CSW_REAL_HOME}/Library" "${stub}/Library"

  # .claude, .claude.json은 계정별로 격리
  ln -sf "${_CSW_ACCOUNTS}/${name}" "${stub}/.claude"
  ln -sf "${_CSW_ACCOUNTS}/${name}/.claude.json" "${stub}/.claude.json"
}

_csw_account_email() {
  local json="${_CSW_ACCOUNTS}/${1}/.claude.json"
  [[ -f "${json}" ]] || return
  local line email
  while IFS= read -r line; do
    if [[ "${line}" =~ \"emailAddress\" ]]; then
      email="${line##*\"emailAddress\": \"}"
      email="${email%%\"*}"
      echo "${email}"
      return
    fi
  done < "${json}"
}

# 계정별 비용 계산 (5시간 블록, LiteLLM 가격 캐시)
# 사용: _csw_calc_costs <tmpfile> <account1> [account2 ...]
# 결과: {"account": cost_usd, ...} JSON → tmpfile
_csw_calc_costs() {
  local _tmpfile="${1}"
  shift
  python3 - "${_CSW_ACCOUNTS}" "$@" > "${_tmpfile}" 2>/dev/null <<'PYEOF'
import os, sys, json, time, urllib.request
from datetime import datetime, timezone

ACCOUNTS_DIR = sys.argv[1]
NAMES        = sys.argv[2:]
CACHE_FILE   = os.path.join(ACCOUNTS_DIR, ".pricing_cache.json")
CACHE_TTL    = 86400  # 24시간

FALLBACK = {
    "claude-opus-4":     {"i": 15.00, "o": 75.00, "cw": 18.75, "cr": 1.50},
    "claude-opus-4-5":   {"i": 15.00, "o": 75.00, "cw": 18.75, "cr": 1.50},
    "claude-sonnet-4-5": {"i":  3.00, "o": 15.00, "cw":  3.75, "cr": 0.30},
    "claude-sonnet-4":   {"i":  3.00, "o": 15.00, "cw":  3.75, "cr": 0.30},
    "claude-haiku-4-5":  {"i":  0.80, "o":  4.00, "cw":  1.00, "cr": 0.08},
    "claude-haiku-3-5":  {"i":  0.80, "o":  4.00, "cw":  1.00, "cr": 0.08},
}

def load_pricing():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE) as f:
                c = json.load(f)
            if time.time() - c.get("ts", 0) < CACHE_TTL:
                return c["p"]
        except: pass
    try:
        url = "https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json"
        with urllib.request.urlopen(url, timeout=5) as r:
            data = json.loads(r.read())
        p = {}
        for m, v in data.items():
            if not m.startswith("claude"): continue
            p[m] = {
                "i":  (v.get("input_cost_per_token") or 0) * 1e6,
                "o":  (v.get("output_cost_per_token") or 0) * 1e6,
                "cw": (v.get("cache_creation_input_token_cost") or 0) * 1e6,
                "cr": (v.get("cache_read_input_token_cost") or 0) * 1e6,
            }
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump({"ts": time.time(), "p": p}, f)
        return p
    except:
        return FALLBACK

def get_price(p, model):
    if model in p: return p[model]
    for k in p:
        if model.startswith(k) or k.startswith(model): return p[k]
    return {"i": 3.0, "o": 15.0, "cw": 3.75, "cr": 0.30}

def calc(name, pr):
    d = os.path.join(ACCOUNTS_DIR, name, "projects")
    if not os.path.isdir(d): return 0.0
    now       = time.time()
    blk_start = (now // 18000) * 18000  # 5시간 블록
    total     = 0.0
    seen      = set()
    for root, _, files in os.walk(d):
        for fn in files:
            if not fn.endswith(".jsonl"): continue
            try:
                with open(os.path.join(root, fn)) as f:
                    for line in f:
                        rec = json.loads(line)
                        if rec.get("isApiErrorMessage"): continue
                        ts = rec.get("timestamp", "")
                        try:
                            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                            if dt.timestamp() < blk_start: continue
                        except: continue
                        msg = rec.get("message", {})
                        if not isinstance(msg, dict): continue
                        key = f"{msg.get('id','')}:{rec.get('requestId','')}"
                        if key in seen: continue
                        seen.add(key)
                        if rec.get("costUSD") is not None:
                            total += rec["costUSD"]; continue
                        u = msg.get("usage")
                        if not u: continue
                        p2 = get_price(pr, msg.get("model", ""))
                        total += (
                            u.get("input_tokens", 0)                * p2["i"]  / 1e6 +
                            u.get("output_tokens", 0)               * p2["o"]  / 1e6 +
                            u.get("cache_creation_input_tokens", 0) * p2["cw"] / 1e6 +
                            u.get("cache_read_input_tokens", 0)     * p2["cr"] / 1e6
                        )
            except: pass
    return total

pr = load_pricing()
print(json.dumps({n: calc(n, pr) for n in NAMES}))
PYEOF
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

  local -a accounts=()
  while IFS= read -r line; do
    accounts+=("${line}")
  done < <(_csw_list_accounts)
  [[ ${#accounts[@]} -eq 0 ]] && return

  echo ""
  printf "\033[2m$(_csw_msg account_list)\033[0m\n"

  # 이메일 미리 수집
  local -A _emails=()
  local acc
  for acc in "${accounts[@]}"; do
    _emails[$acc]=$(_csw_account_email "${acc}")
  done

  # ── 1단계: 모든 내용 즉시 출력, 계정 줄 위치 기록 ────────────────────────
  local -A _acc_line=()   # 계정별 출력 줄 번호 (0-indexed)
  local _line=0

  for acc in "${accounts[@]}"; do
    local _em="${_emails[$acc]:-}"
    [[ -n "${_em}" ]] && _em="  \033[2m${_em}\033[0m"
    if [[ "${acc}" == "${current}" ]]; then
      printf "  \033[1m%-20s\033[0m%b  \033[2m·\033[0m\033[K\n" "${acc}" "${_em}"
    else
      printf "  \033[2m%-20s\033[0m%b  \033[2m·\033[0m\033[K\n" "${acc}" "${_em}"
    fi
    _acc_line[$acc]=${_line}
    (( _line++ ))

    # 핀 정보 즉시 출력
    local pins_file="${_CSW_ACCOUNTS}/.pins/${acc}"
    if [[ -f "${pins_file}" ]]; then
      local -a valid_paths=() proj_path
      while IFS= read -r proj_path; do
        [[ -z "${proj_path}" ]] && continue
        [[ -d "${proj_path}" ]] && valid_paths+=("${proj_path}")
      done < "${pins_file}"
      if [[ ${#valid_paths[@]} -gt 0 ]]; then
        printf "    \033[2m[$(_csw_msg pinned_label)]\033[0m\n"
        (( _line++ ))
        for proj_path in "${valid_paths[@]}"; do
          printf "    \033[2m→\033[0m  %s\n" "${proj_path}"
          (( _line++ ))
        done
      fi
    fi
  done

  local _total=${_line}  # 커서는 출력된 줄 수만큼 아래

  # 게이지 컬럼만 in-place 업데이트하는 헬퍼
  # 커서를 해당 계정 줄로 이동 → 게이지만 덮어씀 → 원위치
  _csw_write_gauge() {
    local _acc="${1}" _gauge="${2}"
    local _dist=$(( _total - _acc_line[$_acc] ))
    local _em="${_emails[$_acc]:-}"
    [[ -n "${_em}" ]] && _em="  \033[2m${_em}\033[0m"
    printf "\033[%dA\r" "${_dist}"
    if [[ "${_acc}" == "${current}" ]]; then
      printf "  \033[1m%-20s\033[0m%b  \033[2m%s\033[0m\033[K" "${_acc}" "${_em}" "${_gauge}"
    else
      printf "  \033[2m%-20s\033[0m%b  \033[2m%s\033[0m\033[K" "${_acc}" "${_em}" "${_gauge}"
    fi
    printf "\033[%dB" "${_dist}"
  }

  # ── 2단계: 백그라운드 비용 계산 ───────────────────────────────────────────
  local _tmpfile
  _tmpfile=$(mktemp)
  _csw_calc_costs "${_tmpfile}" "${accounts[@]}" &
  local _bg_pid=$!

  # ── 3단계: 게이지 영역만 로딩 애니메이션 ─────────────────────────────────
  local -a _frames=("·" "··" "···")
  local _fi=0
  while kill -0 "${_bg_pid}" 2>/dev/null; do
    local _frame="${_frames[$(( _fi % 3 + 1 ))]}"
    for acc in "${accounts[@]}"; do
      _csw_write_gauge "${acc}" "${_frame}"
    done
    sleep 0.2
    (( _fi++ ))
  done
  wait "${_bg_pid}"

  # ── 4단계: 게이지 영역에 최종 결과 렌더 ──────────────────────────────────
  local -a _bars=(
    "░░░░░░░░░░" "▓░░░░░░░░░" "▓▓░░░░░░░░" "▓▓▓░░░░░░░"
    "▓▓▓▓░░░░░░" "▓▓▓▓▓░░░░░" "▓▓▓▓▓▓░░░░" "▓▓▓▓▓▓▓░░░"
    "▓▓▓▓▓▓▓▓░░" "▓▓▓▓▓▓▓▓▓░" "▓▓▓▓▓▓▓▓▓▓"
  )

  if [[ -s "${_tmpfile}" ]]; then
    local _result_json
    _result_json=$(cat "${_tmpfile}")
    local _gauge_lines
    _gauge_lines=$(python3 - "${_result_json}" "${accounts[@]}" <<'PYEOF'
import json, sys
data  = json.loads(sys.argv[1])
names = sys.argv[2:]
mx    = max(data.values()) if data else 0
for n in names:
    c      = data.get(n, 0)
    pct    = int(c / mx * 100) if mx > 0 else 0
    filled = pct * 10 // 100
    print(f"{n}\t{filled}\t{pct}\t${c:.4f}")
PYEOF
    )
    while IFS=$'\t' read -r _name _filled _pct _cost; do
      [[ -z "${_name}" ]] && continue
      _csw_write_gauge "${_name}" "${_bars[$(( _filled + 1 ))]} ${_pct}%  ${_cost}"
    done <<< "${_gauge_lines}"
  else
    for acc in "${accounts[@]}"; do
      _csw_write_gauge "${acc}" "░░░░░░░░░░ 0%  \$0.0000"
    done
  fi
  rm -f "${_tmpfile}"

  printf "\n"
}

# ── claude 래퍼 (진입점) ──────────────────────────────────────────────────────
claude() {
  _csw_ensure_dirs

  if [[ "${1}" == "remote-control" ]]; then
    /opt/homebrew/bin/claude "$@"
    return
  fi

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
    if ! _csw_account_exists "${account}"; then
      printf "[claude account] $(_csw_msg warn_not_found)\n" "${account}" >&2
      command claude "$@"
      return
    fi

    _csw_make_stub "${account}"
    local stub="${_CSW_HOMES}/${account}"

    HOME="${stub}" command claude "$@"
  else
    command claude "$@"
  fi
}
