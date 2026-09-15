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
#      1. 필요한 프로그램 확인 (git, Node.js)
#      2. 없는 도구 설치 (gh, vercel)
#      3. 로그인 (브라우저 승인은 본인이)
#      4. 계정 정보 저장 — 다음부터는 안 물어봅니다
#      5. 사이트 만들고 깃허브에 올리고 버셀에 배포
#
#  이미 되어 있는 단계는 건너뜁니다. 그래서 계정이 없는 사람도,
#  이미 다 갖춘 사람도 똑같이 이 명령 하나만 실행하면 됩니다.
#
#  ※ 비밀번호와 토큰을 받지도, 저장하지도 않습니다.
#     로그인은 브라우저에서 본인이 직접 합니다.
# ============================================================================

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# lib/common.sh 를 불러옵니다. 도구를 찾는 함수(find_gh 등)가 거기 있어서
# 같은 코드를 두 번 쓰지 않아도 됩니다.
source "$HERE/lib/common.sh"

CONFIG_FILE="$HERE/config.sh"

# common.sh 의 출력 함수를 이 스크립트에 맞게 살짝 바꿉니다.
step()  { printf '\n▸ %s\n' "$*"; }
title() { printf '\n%s\n────────────────────────────────────────────────\n' "$*"; }

printf '\n  ██  버셀 원터치\n'
printf '  만든 웹페이지를 인터넷 주소로 띄웁니다\n\n'

# ============================================================================
#  검사는 딱 한 번만
# ----------------------------------------------------------------------------
#  ※ 여기가 중요합니다 ※
#    예전에는 상황을 보여주려고 한 번, 실제로 쓰려고 또 한 번,
#    같은 확인을 두 번씩 했습니다. 그런데 `vercel whoami` 는 3초 넘게 걸립니다.
#    그래서 한 번만 확인하고 그 결과를 변수에 담아 재사용합니다.
#    (20초짜리 작업에서 4초를 아낍니다.)
# ============================================================================
HAS_GIT=0; command -v git >/dev/null 2>&1 && HAS_GIT=1
HAS_NPM=0; command -v npm >/dev/null 2>&1 && HAS_NPM=1
GH_OK=0;   [ -n "$GH" ]     && "$GH" auth status >/dev/null 2>&1 && GH_OK=1
VC_OK=0;   [ -n "$VERCEL" ] && "$VERCEL" whoami  >/dev/null 2>&1 && VC_OK=1

READY=$((HAS_GIT + HAS_NPM + GH_OK + VC_OK))
case "$READY" in
  4) printf '  상황: 준비 완료 — 바로 사이트를 만듭니다 (약 20초)\n' ;;
  3) printf '  상황: 거의 준비됨 — 모자란 것만 채우고 진행합니다\n' ;;
  2) printf '  상황: 도구 설치와 로그인이 필요합니다 (약 2~3분)\n' ;;
  *) printf '  상황: 처음 시작하시는군요 — 하나씩 안내하겠습니다\n' ;;
esac
printf '  이미 되어 있는 것은 자동으로 건너뜁니다.\n'

# ============================================================================
#  1 · 필요한 프로그램
# ----------------------------------------------------------------------------
#  git 과 Node.js 는 자동 설치하지 않습니다. 설치 중에 고를 것이 있고
#  잘못 깔면 되돌리기 번거롭기 때문입니다. 없으면 받는 곳만 알려주고 멈춥니다.
# ============================================================================
if [ "$HAS_GIT" -eq 0 ] || [ "$HAS_NPM" -eq 0 ]; then
  title "필요한 프로그램이 없습니다"
  [ "$HAS_GIT" -eq 0 ] && note "git       https://git-scm.com/downloads"
  [ "$HAS_NPM" -eq 0 ] && note "Node.js   https://nodejs.org   (npm 이 함께 깔립니다)"
  printf '\n  둘 다 기본 설정 그대로 "다음"만 누르면 됩니다.\n'
  printf '  설치한 뒤 터미널을 껐다 켜고 다시 실행하세요:\n\n      bash start.sh\n\n'
  exit 1
fi

# ============================================================================
#  2 · 도구 설치 (없을 때만)
# ============================================================================
if [ -z "$GH" ] || [ -z "$VERCEL" ]; then
  title "도구 설치"

  if [ -z "$GH" ]; then
    note "gh 를 설치합니다..."
    case "$(uname -s)" in
      MINGW*|MSYS*|CYGWIN*)
        # --scope user : 관리자 권한 없이 내 계정 폴더에만 설치
        winget install --id GitHub.cli -e --scope user \
          --accept-package-agreements --accept-source-agreements --disable-interactivity \
          >/dev/null 2>&1 || die "gh 설치 실패. https://cli.github.com 에서 직접 설치해 주세요." ;;
      Darwin)
        command -v brew >/dev/null 2>&1 || die "Homebrew 가 없습니다. https://brew.sh"
        brew install gh >/dev/null 2>&1 || die "gh 설치 실패" ;;
      Linux)
        if   command -v apt >/dev/null 2>&1; then sudo apt update -qq && sudo apt install -y gh
        elif command -v dnf >/dev/null 2>&1; then sudo dnf install -y gh
        else die "gh 를 직접 설치해 주세요: https://cli.github.com"; fi ;;
      *) die "이 운영체제는 자동 설치를 지원하지 않습니다: https://cli.github.com" ;;
    esac
    GH="$(find_gh || true)"
    [ -n "$GH" ] || die "gh 를 설치했지만 찾지 못했습니다. 터미널을 껐다 켜고 다시 실행해 주세요."
    note "gh       설치 완료"
  fi

  if [ -z "$VERCEL" ]; then
    note "vercel 을 설치합니다... (1~2분 걸릴 수 있습니다)"
    npm install -g vercel >/dev/null 2>&1 || die "vercel 설치 실패"
    VERCEL="$(find_vercel || true)"
    [ -n "$VERCEL" ] || die "vercel 을 설치했지만 찾지 못했습니다. 터미널을 껐다 켜고 다시 실행해 주세요."
    note "vercel   설치 완료"
  fi
fi

# ============================================================================
#  3 · 로그인 (안 되어 있을 때만)
# ============================================================================
if [ "$GH_OK" -eq 0 ]; then
  title "깃허브 로그인"
  printf '  계정이 아직 없다면 먼저 만들고 오세요 (무료):\n'
  printf '      https://github.com/signup\n\n'
  printf '  브라우저가 열리면\n'
  printf '   1) 화면에 뜨는 8자리 코드를 복사해 붙여넣고\n'
  printf '   2) Authorize 를 눌러 승인하세요.\n\n'
  "$GH" auth login --hostname github.com --git-protocol https --web \
        --scopes "repo,delete_repo" \
    || die "깃허브 로그인에 실패했습니다.
  계정이 없다면 https://github.com/signup 에서 먼저 가입한 뒤
  다시 실행해 주세요:  bash start.sh"
fi

if [ "$VC_OK" -eq 0 ]; then
  title "버셀 로그인"
  printf '  계정이 아직 없다면 먼저 만들고 오세요 (무료):\n'
  printf '      https://vercel.com/signup\n'
  printf '      → "Continue with GitHub" 를 고르면 깃허브 계정으로 바로 가입됩니다.\n'
  printf '        비밀번호를 새로 만들 필요가 없습니다.\n\n'
  printf '  2단계 인증(Authenticator)은 설정하지 않아도 됩니다.\n\n'
  "$VERCEL" login \
    || die "버셀 로그인에 실패했습니다.
  계정이 없다면 https://vercel.com/signup 에서 'Continue with GitHub' 로
  가입한 뒤 다시 실행해 주세요:  bash start.sh"
fi

# ============================================================================
#  4 · 설정 저장 (없을 때만)
# ----------------------------------------------------------------------------
#  아이디와 폴더 경로만 저장합니다. 비밀번호·토큰은 저장하지 않습니다.
#  .gitignore 에 있어서 깃허브에 올라가지 않습니다.
# ============================================================================
if [ ! -f "$CONFIG_FILE" ]; then
  title "설정 저장"

  GH_OWNER="$("$GH" api /user --jq .login)"
  GIT_EMAIL="$("$GH" api /user --jq '.email // ""')"
  [ -n "$GIT_EMAIL" ] || GIT_EMAIL="$GH_OWNER@users.noreply.github.com"

  # ★ 함정 ★ vercel 은 목록 표를 stdout 이 아니라 stderr 로 출력합니다.
  #   2>/dev/null 로 버리면 표가 통째로 사라집니다. 2>&1 로 합쳐야 합니다.
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
fi

# ============================================================================
#  5 · 사이트 만들고 배포
# ----------------------------------------------------------------------------
#  이름을 안 주면 my-first-site 로 데모를 하나 만듭니다.
# ============================================================================
SITE_NAME=""
if [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; then
  SITE_NAME="$1"; shift
fi
if [ -z "$SITE_NAME" ]; then
  SITE_NAME="my-first-site"
  set -- --title "첫 번째 사이트" "$@"
fi

bash "$HERE/new-site.sh" "$SITE_NAME" "$@"

printf '\n다음부터는 이렇게 쓰면 됩니다  (이 폴더에서)\n'
printf '────────────────────────────────────────────────\n'
printf '  bash new-site.sh 이름 --title "제목"    사이트 더 만들기\n'
printf '  bash publish.sh --dir 폴더 "메모"       고친 내용 올리기\n'
printf '  bash protect.sh 이름 on                나만 보기\n'
printf '  bash protect.sh 이름 off               다시 공개\n'
printf '  bash remove-site.sh 이름               통째로 내리기\n'
printf '\nClaude Code 를 쓰신다면 말로 하셔도 됩니다.\n'
printf '  "새 사이트 만들어줘"   "고친 거 올려줘"   "잠가줘"   "내려줘"\n\n'
