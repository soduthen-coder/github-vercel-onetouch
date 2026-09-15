#!/usr/bin/env bash
# ============================================================================
#  start.sh — 버셀 원터치 · 처음 시작하는 사람을 위한 단 하나의 명령
# ----------------------------------------------------------------------------
#  실행 방법
#
#      bash start.sh                        데모 사이트를 하나 만들어 봅니다
#      bash start.sh my-site                이름을 정해서 만듭니다
#      bash start.sh my-site --title "내 사이트"
#      bash start.sh my-site --public       공개 저장소로 만듭니다
#
#  이 하나가 처음부터 끝까지 다 합니다
#      1. 필요한 프로그램이 있는지 확인 (git, Node.js)
#      2. 없는 도구 설치 (gh, vercel)
#      3. 로그인 (브라우저 승인은 본인이)
#      4. 계정 정보 저장 — 다음부터는 안 물어봅니다
#      5. 사이트 만들고 깃허브에 올리고 버셀에 배포
#      6. 진짜 열리는지 접속해서 확인
#
#  두 번째부터는 1~4 를 자동으로 건너뜁니다. 그때는 사이트만 만들어집니다.
#
#  ※ 비밀번호와 토큰을 받지도, 저장하지도 않습니다.
#     로그인은 브라우저에서 본인이 직접 합니다.
# ============================================================================

set -euo pipefail
export MSYS_NO_PATHCONV=1

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HERE/config.sh"

step()  { printf '\n▸ %s\n' "$*"; }
note()  { printf '  %s\n' "$*"; }
die()   { printf '\n✖ %s\n' "$*" >&2; exit 1; }
title() { printf '\n%s\n' "$*"; printf '%s\n' "────────────────────────────────────────────────"; }

printf '\n'
printf '  ██  버셀 원터치\n'
printf '  만든 웹페이지를 인터넷 주소로 띄웁니다\n'
printf '\n'

# ============================================================================
#  0단계 · 지금 상황 진단
# ----------------------------------------------------------------------------
#  이 스크립트는 "이미 되어 있는 것"을 건너뜁니다.
#  그래서 처음 쓰는 사람도, 계정이 이미 있는 사람도, 커넥터까지 연동한
#  사람도 똑같이 이 명령 하나만 실행하면 됩니다.
#  아래는 지금 어느 상황인지 보여주는 것뿐입니다. 뭘 고르실 필요는 없습니다.
# ============================================================================
READY=0
command -v git  >/dev/null 2>&1 && READY=$((READY+1))
command -v npm  >/dev/null 2>&1 && READY=$((READY+1))
command -v gh   >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && READY=$((READY+1))
command -v vercel >/dev/null 2>&1 && vercel whoami >/dev/null 2>&1 && READY=$((READY+1))

case "$READY" in
  4) printf '  상황: 준비 완료 — 바로 사이트를 만듭니다 (약 20초)\n' ;;
  3) printf '  상황: 거의 준비됨 — 모자란 것만 채우고 진행합니다\n' ;;
  2) printf '  상황: 도구 설치와 로그인이 필요합니다 (약 2~3분)\n' ;;
  *) printf '  상황: 처음 시작하시는군요 — 하나씩 안내하겠습니다\n' ;;
esac
printf '  이미 되어 있는 것은 자동으로 건너뜁니다.\n\n'

# ============================================================================
#  1단계 · 필요한 프로그램 확인
# ----------------------------------------------------------------------------
#  git 과 Node.js 는 자동으로 설치하지 않습니다.
#  설치 중에 고를 것이 있고, 잘못 깔면 되돌리기 번거롭기 때문입니다.
#  없으면 어디서 받는지 알려주고 멈춥니다.
# ============================================================================
title "1단계 · 필요한 프로그램 확인"

MISSING=""
if command -v git >/dev/null 2>&1; then
  note "git      있음  ($(git --version | head -1))"
else
  MISSING="$MISSING\n    git       https://git-scm.com/downloads"
fi
if command -v npm >/dev/null 2>&1; then
  note "Node.js  있음  (npm $(npm --version 2>/dev/null))"
else
  MISSING="$MISSING\n    Node.js   https://nodejs.org   (npm 이 함께 깔립니다)"
fi

if [ -n "$MISSING" ]; then
  printf '\n  아래 프로그램을 먼저 설치해 주세요:%b\n' "$MISSING"
  printf '\n  둘 다 기본 설정 그대로 "다음"만 누르면 됩니다.\n'
  printf '  설치한 뒤 터미널을 껐다 켜고 다시 실행하세요:\n\n'
  printf '      bash start.sh\n\n'
  exit 1
fi

# ============================================================================
#  2단계 · 도구 설치 (gh, vercel)
# ----------------------------------------------------------------------------
#  gh      깃허브를 명령으로 다루는 공식 도구
#  vercel  버셀에 배포하는 공식 도구
#  이미 있으면 건너뜁니다.
# ============================================================================
title "2단계 · 도구 확인"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) OS="windows" ;;
  Darwin)               OS="mac" ;;
  Linux)                OS="linux" ;;
  *)                    OS="unknown" ;;
esac

find_gh() {
  command -v gh 2>/dev/null && return
  local c
  for c in "$HOME/AppData/Local/Microsoft/WinGet/Packages"/GitHub.cli_*/bin/gh.exe \
           "/c/Program Files/GitHub CLI/gh.exe" "/opt/homebrew/bin/gh" "/usr/local/bin/gh"; do
    [ -x "$c" ] && { printf '%s' "$c"; return; }
  done
  return 1
}

GH="$(find_gh || true)"
if [ -n "$GH" ]; then
  note "gh       있음"
else
  note "gh       설치합니다..."
  case "$OS" in
    windows)
      # --scope user : 관리자 권한 없이 내 계정 폴더에만 설치
      winget install --id GitHub.cli -e --scope user \
        --accept-package-agreements --accept-source-agreements --disable-interactivity \
        >/dev/null 2>&1 || die "gh 설치 실패. https://cli.github.com 에서 직접 설치해 주세요." ;;
    mac)
      command -v brew >/dev/null 2>&1 || die "Homebrew 가 없습니다. https://brew.sh"
      brew install gh >/dev/null 2>&1 || die "gh 설치 실패" ;;
    linux)
      if   command -v apt >/dev/null 2>&1; then sudo apt update -qq && sudo apt install -y gh
      elif command -v dnf >/dev/null 2>&1; then sudo dnf install -y gh
      else die "gh 를 직접 설치해 주세요: https://cli.github.com"; fi ;;
    *) die "이 운영체제는 자동 설치를 지원하지 않습니다: https://cli.github.com" ;;
  esac
  GH="$(find_gh || true)"
  [ -n "$GH" ] || die "gh 를 설치했지만 찾지 못했습니다. 터미널을 껐다 켜고 다시 실행해 주세요."
  note "gh       설치 완료"
fi

if command -v vercel >/dev/null 2>&1; then
  note "vercel   있음"
else
  note "vercel   설치합니다... (1~2분 걸릴 수 있습니다)"
  npm install -g vercel >/dev/null 2>&1 || die "vercel 설치 실패"
  note "vercel   설치 완료"
fi
VERCEL="$(command -v vercel)"

# ============================================================================
#  3단계 · 로그인
# ----------------------------------------------------------------------------
#  계정이 없으면 여기서 가입 주소를 안내합니다.
#  로그인 자체는 브라우저에서 본인이 직접 합니다.
# ============================================================================
title "3단계 · 로그인"

if "$GH" auth status >/dev/null 2>&1; then
  note "깃허브   로그인됨 ($("$GH" api /user --jq .login 2>/dev/null))"
else
  printf '\n  깃허브 계정이 필요합니다.\n'
  printf '  아직 없다면 먼저 만들고 오세요 (무료):\n'
  printf '      https://github.com/signup\n\n'
  printf '  이제 로그인합니다. 브라우저가 열리면\n'
  printf '   1) 화면에 뜨는 8자리 코드를 복사해 붙여넣고\n'
  printf '   2) Authorize 를 눌러 승인하세요.\n\n'
  "$GH" auth login --hostname github.com --git-protocol https --web \
        --scopes "repo,delete_repo" \
    || die "깃허브 로그인에 실패했습니다.
  계정이 없다면 https://github.com/signup 에서 먼저 가입한 뒤
  다시 실행해 주세요:  bash start.sh"
  note "깃허브   로그인 완료"
fi

if "$VERCEL" whoami >/dev/null 2>&1; then
  note "버셀     로그인됨"
else
  printf '\n  버셀 계정이 필요합니다.\n'
  printf '  아직 없다면 먼저 만들고 오세요 (무료):\n'
  printf '      https://vercel.com/signup\n'
  printf '      → "Continue with GitHub" 를 고르면 방금 만든 깃허브 계정으로\n'
  printf '        바로 가입됩니다. 비밀번호를 새로 만들 필요가 없습니다.\n\n'
  printf '  2단계 인증(Authenticator)은 설정하지 않아도 됩니다.\n\n'
  "$VERCEL" login \
    || die "버셀 로그인에 실패했습니다.
  계정이 없다면 https://vercel.com/signup 에서 'Continue with GitHub' 로
  가입한 뒤 다시 실행해 주세요:  bash start.sh"
  note "버셀     로그인 완료"
fi

# ============================================================================
#  4단계 · 설정 저장
# ----------------------------------------------------------------------------
#  아이디와 폴더 경로만 저장합니다. 비밀번호·토큰은 저장하지 않습니다.
#  이 파일은 .gitignore 에 있어 깃허브에 올라가지 않습니다.
# ============================================================================
title "4단계 · 설정 저장"

GH_OWNER="$("$GH" api /user --jq .login)"
GIT_EMAIL="$("$GH" api /user --jq '.email // ""')"
[ -n "$GIT_EMAIL" ] || GIT_EMAIL="$GH_OWNER@users.noreply.github.com"

# ★ 함정 ★ vercel 은 목록 표를 stdout 이 아니라 stderr 로 출력합니다.
#   2>/dev/null 로 버리면 표가 통째로 사라집니다. 2>&1 로 합쳐야 합니다.
#   현재 팀 앞에 붙는 "√" 표시도 떼어냅니다.
VERCEL_SCOPE="$("$VERCEL" teams ls 2>&1 \
  | sed 's/\r//' \
  | sed 's/^[√>*✔•]\+[[:space:]]*//' \
  | grep -vE '^\s*<' \
  | awk '$1!="" && $1!="id" && $1 !~ /^(Vercel|Fetching|Error|Retrieving)/ && $2!="" {print $1; exit}' \
  || true)"

DEFAULT_PARENT="$(cd "$HERE/.." && pwd)/sites"

cat > "$CONFIG_FILE" <<CFG
#!/usr/bin/env bash
# start.sh 가 자동으로 만든 파일입니다.
# 아이디와 폴더 경로만 들어 있습니다. 비밀번호·토큰은 없습니다.
GH_OWNER="$GH_OWNER"
GIT_NAME="$GH_OWNER"
GIT_EMAIL="$GIT_EMAIL"
VERCEL_SCOPE="$VERCEL_SCOPE"
DEFAULT_PARENT="$DEFAULT_PARENT"
CFG
mkdir -p "$DEFAULT_PARENT"

note "깃허브 아이디  $GH_OWNER"
note "버셀 팀        ${VERCEL_SCOPE:-(개인 계정)}"
note "사이트 폴더    $DEFAULT_PARENT"

# ============================================================================
#  5단계 · 사이트 만들고 배포
# ----------------------------------------------------------------------------
#  이름을 안 주면 my-first-site 로 데모를 하나 만듭니다.
# ============================================================================
title "5단계 · 사이트 만들고 배포"

SITE_NAME="${1:-}"
if [ -n "$SITE_NAME" ] && [ "${SITE_NAME#--}" != "$SITE_NAME" ]; then
  SITE_NAME=""            # 첫 인자가 옵션이면 이름이 아님
else
  [ $# -gt 0 ] && shift || true
fi

if [ -z "$SITE_NAME" ]; then
  SITE_NAME="my-first-site"
  set -- --title "첫 번째 사이트" "$@"
  note "이름을 안 주셔서 '$SITE_NAME' 으로 만듭니다."
fi

bash "$HERE/new-site.sh" "$SITE_NAME" "$@"

# ============================================================================
#  안내
# ============================================================================
printf '\n'
printf '다음부터는 이렇게 쓰면 됩니다\n'
printf '────────────────────────────────────────────────\n'
printf '  사이트 더 만들기   bash "%s/new-site.sh" 이름\n' "$HERE"
printf '  고친 내용 올리기   bash "%s/publish.sh" --dir 폴더 "메모"\n' "$HERE"
printf '  나만 보기          bash "%s/protect.sh" 이름 on\n' "$HERE"
printf '  다시 공개          bash "%s/protect.sh" 이름 off\n' "$HERE"
printf '  통째로 내리기      bash "%s/remove-site.sh" 이름\n' "$HERE"
printf '\n'
printf 'Claude Code 를 쓰신다면 그냥 말로 하셔도 됩니다.\n'
printf '  "새 사이트 만들어줘"   "고친 거 올려줘"   "잠가줘"   "내려줘"\n\n'
