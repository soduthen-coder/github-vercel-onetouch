#!/usr/bin/env bash
# ============================================================================
#  remove-site.sh — 사이트를 통째로 내린다
#                   (깃허브 저장소 · 버셀 프로젝트 · 로컬 폴더)
# ----------------------------------------------------------------------------
#  사용법
#      bash remove-site.sh <이름>
#      bash remove-site.sh <이름> --keep-local     폴더는 남긴다
#      bash remove-site.sh <이름> --keep-repo      저장소는 남긴다
#
#  ★★ 되돌릴 수 없습니다 ★★
#    지우기 전에 무엇을 지울지 보여주고, 프로젝트 이름을 한 번 더
#    입력받습니다. 오타로 엉뚱한 걸 지우는 사고를 막기 위해서입니다.
#    이 확인 절차는 일부러 남겨두었습니다. 없애지 마세요.
#
#  Claude Code 로 쓰실 때는 대화에서 "내려줘" 라고 하신 것이 확인이 되고,
#  Claude 가 확인값을 대신 넣어 실행합니다. 그래도 지우기 전에
#  무엇을 지울지 먼저 보여드립니다.
# ============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

NAME="${1:-}"
[ -z "$NAME" ] && die "사용법: bash remove-site.sh <이름> [--keep-local] [--keep-repo]"
shift

KEEP_LOCAL=0
KEEP_REPO=0
while [ $# -gt 0 ]; do
  case "$1" in
    --keep-local) KEEP_LOCAL=1 ;;
    --keep-repo)  KEEP_REPO=1 ;;
    *) die "모르는 옵션입니다: $1" ;;
  esac
  shift
done

check_auth
DIR="$DEFAULT_PARENT/$NAME"

# ----------------------------------------------------------------------------
# 1) 무엇을 지울지 먼저 보여준다
#    "0KB 짜리 빈 저장소" 인지 "내용이 든 저장소" 인지 크기로 알 수 있습니다.
# ----------------------------------------------------------------------------
printf '\n지울 대상\n'
printf '─────────────────────────────────────────────\n'

if [ "$KEEP_REPO" -eq 0 ]; then
  INFO="$("$GH" api "/repos/$GH_OWNER/$NAME" \
        --jq '"  저장소  \(.full_name)  [\(.visibility)]  만든날 \(.created_at[0:10])  \(.size)KB"' \
        2>/dev/null || echo '  저장소  (없음)')"
  printf '%s\n' "$INFO"
else
  printf '  저장소  건너뜀 (--keep-repo)\n'
fi

# 지우고 나면 주소를 알아낼 방법이 없으므로, 지우기 전에 기억해 둡니다.
# (추측한 주소는 남의 사이트일 수 있어 쓰지 않습니다.)
SITE_BEFORE="$(site_url "$NAME")"
if [ -n "$SITE_BEFORE" ]; then
  printf '  버셀    %s  (%s)\n' "$NAME" "$SITE_BEFORE"
else
  printf '  버셀    (없음)\n'
fi

if [ "$KEEP_LOCAL" -eq 0 ] && [ -d "$DIR" ]; then
  printf '  폴더    %s\n' "$DIR"
else
  printf '  폴더    건너뜀\n'
fi
printf '─────────────────────────────────────────────\n'

# ----------------------------------------------------------------------------
# 2) 확인 받기
#    read 는 사용자의 입력을 기다립니다.
#    프로젝트 이름을 정확히 다시 쳐야만 진행합니다.
# ----------------------------------------------------------------------------
printf '되돌릴 수 없습니다. 계속하려면 프로젝트 이름을 그대로 입력하세요:\n'
read -r CONFIRM
[ "$CONFIRM" = "$NAME" ] || die "입력이 달라 취소했습니다."

# ----------------------------------------------------------------------------
# 3) 실제로 지우기
# ----------------------------------------------------------------------------
if [ "$KEEP_REPO" -eq 0 ]; then
  step "깃허브 저장소 삭제"
  "$GH" repo delete "$GH_OWNER/$NAME" --yes 2>&1 | head -2 \
    || note "저장소가 없거나 삭제 권한이 없습니다 (setup.sh 를 다시 실행해 보세요)"
fi

step "버셀 프로젝트 삭제"
# vercel project rm 은 확인을 묻기 때문에 "y" 를 미리 넣어 줍니다.
echo "y" | vc project rm "$NAME" 2>&1 \
  | grep -oE "Success![^[]*|Error[^[]*" | head -1 || true

if [ "$KEEP_LOCAL" -eq 0 ] && [ -d "$DIR" ]; then
  step "로컬 폴더 삭제"
  rm -rf "$DIR"
fi

# ----------------------------------------------------------------------------
# 4) 정말 지워졌는지 확인
#    "지웠습니다" 라고만 하지 않고 실제로 다시 조회해 봅니다.
# ----------------------------------------------------------------------------
step "정말 지워졌는지 확인"
if "$GH" api "/repos/$GH_OWNER/$NAME" >/dev/null 2>&1; then
  note "저장소가 아직 남아 있습니다"
else
  note "저장소 없음 ✓"
fi
if [ -n "$SITE_BEFORE" ]; then
  # 버셀은 삭제 직후 몇 초 동안 예전 내용을 계속 내려줍니다.
  # 바로 확인하면 "아직 살아 있다"고 잘못 보고하게 되므로 몇 번 다시 봅니다.
  CODE="000"
  for _ in 1 2 3 4 5; do
    CODE="$(http_code "$SITE_BEFORE")"
    [ "$CODE" = "404" ] && break
    sleep 3
  done
  if [ "$CODE" = "404" ]; then
    note "사이트 내려감 ✓  (HTTP 404)"
  else
    note "사이트 응답: HTTP $CODE — 전파에 시간이 더 걸릴 수 있습니다."
    note "잠시 뒤 다시 확인해 보세요:  curl -s -o /dev/null -w '%{http_code}' -L $SITE_BEFORE"
  fi
else
  note "사이트: 원래 배포가 없었습니다"
fi

printf '\n완료: %s\n' "$NAME"
