#!/usr/bin/env bash
# ============================================================================
#  new-site.sh — 새 사이트를 깃허브 저장소 + 버셀 배포까지 한 번에 만든다
# ----------------------------------------------------------------------------
#  사용법
#      bash new-site.sh <영문-이름> [옵션]
#
#  예시
#      bash new-site.sh portfolio
#      bash new-site.sh portfolio --title "내 포트폴리오"
#      bash new-site.sh portfolio --public          (공개 저장소로)
#      bash new-site.sh portfolio --dir "D:/작업"    (다른 폴더에 만들기)
#
#  옵션
#      --title "글자"   웹페이지에 보일 제목 (한글 가능)
#      --public         저장소를 공개로 만든다 (기본값은 비공개)
#      --private        저장소를 비공개로 만든다 (기본값)
#      --dir 경로       프로젝트를 만들 상위 폴더
#
#  ★ 이름은 반드시 영소문자·숫자·하이픈 ★
#     깃허브는 한글 이름을 "-" 한 글자로 뭉개버리고,
#     버셀은 한글 폴더에서 링크 오류를 냅니다. 실제로 겪은 문제입니다.
#     한글은 --title 로 주세요. 화면에 보이는 제목으로만 쓰입니다.
#
#  약 15~20초 걸립니다. 끝나면 주소를 보여주고, 실제로 열리는지도 확인합니다.
# ============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

# ----------------------------------------------------------------------------
# 1) 입력값 받기
# ----------------------------------------------------------------------------
NAME="${1:-}"
if [ -z "$NAME" ]; then
  die "사용법: bash new-site.sh <영문-이름> [--title \"제목\"] [--public]"
fi
shift

# 화면에 보이는 제목은 사용자가 준 그대로 씁니다 (한글이어도 됩니다).
# 저장소·폴더 이름만 깃허브가 받는 형태로 바꿉니다.
TITLE="$NAME"
NAME="$(check_name "$NAME")"

VIS="--private"             # 기본은 비공개. 실수로 공개되는 사고를 막기 위해서입니다
PARENT=""                   # 비어 있으면 아래에서 설정값을 씁니다

while [ $# -gt 0 ]; do
  case "$1" in
    --title)   TITLE="${2:-}"; shift ;;
    --public)  VIS="--public" ;;
    --private) VIS="--private" ;;
    --dir)     PARENT="${2:-}"; shift ;;
    *) die "모르는 옵션입니다: $1" ;;
  esac
  shift
done

check_auth                                  # 로그인 상태를 미리 확인
PARENT="${PARENT:-$DEFAULT_PARENT}"
DIR="$PARENT/$NAME"
[ -e "$DIR" ] && die "이미 있는 폴더입니다: $DIR"

# ----------------------------------------------------------------------------
# 2) 폴더와 기본 파일 만들기
#    index.html 하나면 버셀이 알아서 웹사이트로 인식합니다.
#    빌드 설정도, vercel.json 같은 설정 파일도 필요 없습니다.
# ----------------------------------------------------------------------------
step "폴더 만들기   $DIR"
mkdir -p "$DIR"
cd "$DIR"

step "기본 파일 만들기 (index.html, README.md, .gitignore)"
cat > index.html <<HTML
<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$TITLE</title>
<style>
/* 노랑은 '채움' 으로만 씁니다. 흰 배경 위 노란 글씨는 읽히지 않습니다. */
:root{
  color-scheme:light;
  --paper:#fff; --ink:#171613; --ink-2:#57544c; --ink-3:#8c887e;
  --rule:#e6e3da; --hi:#ffd400; --hi-soft:#fff3bf;
}
*{box-sizing:border-box}
body{
  margin:0;background:var(--paper);color:var(--ink);
  font-family:'Pretendard Variable',Pretendard,-apple-system,BlinkMacSystemFont,
    'Apple SD Gothic Neo','Malgun Gothic',sans-serif;
  font-size:17px;line-height:1.75;letter-spacing:-.01em;
  word-break:keep-all;               /* 한글이 단어 중간에서 끊기지 않게 */
  display:flex;align-items:center;justify-content:center;
  min-height:100vh;padding:28px;
}
main{max-width:560px;width:100%}
h1{font-size:clamp(26px,6vw,36px);font-weight:800;letter-spacing:-.035em;
   line-height:1.3;margin:0 0 14px}
.mark{background:linear-gradient(to top,var(--hi) 40%,transparent 40%);padding:0 2px}
p{margin:0 0 10px;color:var(--ink-2);font-size:16px}
.hint{color:var(--ink-3);font-size:14.5px;border-top:1px solid var(--rule);
      margin-top:22px;padding-top:16px}
code{font-family:'SF Mono',SFMono-Regular,Menlo,Consolas,monospace;
     font-size:.88em;background:var(--hi-soft);padding:2px 6px;border-radius:4px;
     letter-spacing:0}
</style>
</head>
<body>
  <main>
    <h1><span class="mark">$TITLE</span></h1>
    <p>여기에 내용을 채우세요.</p>
    <p class="hint"><code>index.html</code> 을 고친 뒤
       <code>publish.sh</code> 를 실행하면 깃허브와 버셀에 함께 반영됩니다.</p>
  </main>
</body>
</html>
HTML

# .gitignore : "이 파일들은 깃허브에 올리지 마라" 목록입니다.
# 열쇠 파일이 한 번 올라가면 지워도 커밋 기록에 남습니다. 미리 막는 게 중요합니다.
cat > .gitignore <<'IGN'
# 열쇠·비밀 파일 — 절대 올리면 안 되는 것들
.env
.env.*
*.pem
*.key
# 버셀이 만드는 로컬 설정 폴더 (토큰이 들어 있습니다)
.vercel/
# 운영체제·편집기가 만드는 잡파일
.DS_Store
Thumbs.db
.vscode/
.idea/
IGN

cat > README.md <<MD
# $TITLE

정적 사이트입니다. \`index.html\` 하나로 동작하며 빌드 설정이 없습니다.

\`index.html\` 을 고친 뒤 도구 폴더에서 아래를 실행하면 깃허브와 버셀에
함께 반영됩니다.

\`\`\`bash
bash publish.sh --dir "$DIR" "무엇을 고쳤는지"
bash protect.sh $NAME on     # 나만 보기
bash protect.sh $NAME off    # 다시 공개
\`\`\`
MD

# ----------------------------------------------------------------------------
# 3) git 저장소로 만들고 첫 커밋
#    git init   : 이 폴더를 버전 관리 대상으로 삼는다
#    git add -A : 바뀐 파일 전부를 "올릴 목록"에 담는다
#    git commit : 그 목록을 하나의 기록으로 확정한다
# ----------------------------------------------------------------------------
step "git 저장소 만들고 첫 기록 남기기"
git init -q
git config core.quotepath false          # 한글 파일명이 깨져 보이지 않게
git config user.name  "$GIT_NAME"
git config user.email "$GIT_EMAIL"
git branch -M main                        # 기본 가지 이름을 main 으로
git add -A
git commit -q -m "$NAME 첫 커밋"

# ----------------------------------------------------------------------------
# 4) 깃허브에 저장소를 만들고 밀어 올리기
#    --source=.   지금 폴더를 그대로 올린다
#    --push       만들자마자 업로드까지 한다
# ----------------------------------------------------------------------------
step "깃허브 저장소 만들기 + 업로드   (${VIS#--})"
"$GH" repo create "$NAME" $VIS --source=. --remote=origin --push >/dev/null 2>&1 \
  || die "깃허브 저장소 만들기 실패. 같은 이름이 이미 있는지 확인해 주세요."

# ----------------------------------------------------------------------------
# 5) 버셀에 배포
#    --prod 를 붙여 정식 주소(...vercel.app)로 올립니다.
#    깃허브 연동을 따로 걸지 않고 여기서 바로 올리기 때문에,
#    버셀 깃허브 앱 권한 설정 같은 수동 단계가 필요 없습니다.
# ----------------------------------------------------------------------------
step "버셀에 배포"
OUT="$TOOLS/.out_$$.txt"; ERR="$TOOLS/.err_$$.txt"
trap 'rm -f "$OUT" "$ERR"' EXIT
if ! vc deploy --prod --yes >"$OUT" 2>"$ERR"; then
  printf '\n배포 실패 내용:\n'; tail -6 "$ERR"
  die "버셀 배포에 실패했습니다."
fi

# 배포 결과에서 주소를 뽑아냅니다.
SITE="$(grep -oE 'Aliased +https://[^ ]+' "$ERR" | head -1 | awk '{print $2}')"
[ -n "$SITE" ] || SITE="https://$(grep -oE '"url": *"[^"]+"' "$OUT" | head -1 | sed 's/.*"url": *"//;s/"//')"

# ----------------------------------------------------------------------------
# 6) 진짜 열리는지 확인
#    "배포했습니다" 라고만 하지 않고, 실제로 주소를 열어 응답을 봅니다.
# ----------------------------------------------------------------------------
step "실제로 열리는지 확인"
CODE="$(http_code "$SITE")"
TITLE_SEEN="$(page_title "$SITE")"

printf '\n─────────────────────────────────────────────\n'
printf ' 완료:  %s\n' "$TITLE"
printf ' 사이트  %s   (HTTP %s)\n' "$SITE" "$CODE"
printf ' 보이는 제목  %s\n' "${TITLE_SEEN:--}"
printf ' 저장소  https://github.com/%s/%s\n' "$GH_OWNER" "$NAME"
printf ' 폴더    %s\n' "$DIR"
printf '─────────────────────────────────────────────\n'
