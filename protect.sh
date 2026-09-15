#!/usr/bin/env bash
# ============================================================================
#  protect.sh — 배포한 사이트를 잠그거나 공개한다
# ----------------------------------------------------------------------------
#  사용법
#      bash protect.sh <이름> on      잠금 — 버셀에 로그인한 나만 볼 수 있음
#      bash protect.sh <이름> off     공개 — 주소를 아는 누구나 볼 수 있음
#      bash protect.sh <이름>         지금 상태만 확인
#
#      --repo 를 붙이면 깃허브 저장소의 공개 범위도 같이 바꿉니다.
#          bash protect.sh my-site off --repo
#
#  ★ 왜 필요한가 ★
#    버셀은 배포하면 기본적으로 "주소를 아는 사람은 누구나" 볼 수 있습니다.
#    검색에는 잘 안 걸리지만, 주소가 알려지면 그대로 열립니다.
#    개인정보나 아직 안 보여주고 싶은 작업이 들어 있다면 잠가 두세요.
#
#  ★ 잠그면 어떻게 되나 ★
#    사이트 주소로 들어가면 버셀 로그인 화면이 뜹니다.
#    본인이 로그인하면 정상적으로 보이고, 남에게는 안 보입니다.
#    과제 제출처럼 남이 링크를 열어야 하면 잠그면 안 됩니다.
#
#  참고: 비밀번호로 잠그는 기능(Password Protection)은 버셀 유료 요금제
#        기능입니다. 여기서 쓰는 방식(Vercel Authentication)은 무료입니다.
# ============================================================================

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/common.sh"

NAME="${1:-}"
[ -z "$NAME" ] && die "사용법: bash protect.sh <이름> [on|off] [--repo]"
shift

ACTION="status"      # 기본은 조회만
ALSO_REPO=0
while [ $# -gt 0 ]; do
  case "$1" in
    on|off) ACTION="$1" ;;
    --repo) ALSO_REPO=1 ;;
    *) die "모르는 옵션입니다: $1" ;;
  esac
  shift
done

check_auth

# ----------------------------------------------------------------------------
# 설정 파일을 임시로 만들어 버셀 API 에 넘깁니다.
#
# ★ 윈도우 주의점 ★
#   버셀 도구는 윈도우 프로그램이라 "/tmp/파일" 을 "C:\tmp\파일" 로 해석합니다.
#   그래서 /tmp 가 아니라 이 도구 폴더 안에 임시 파일을 만듭니다.
#   (이것 때문에 처음에 "설정 변경 실패" 가 났었습니다.)
# ----------------------------------------------------------------------------
TMP="$TOOLS/.protect_$$.json"
trap 'rm -f "$TMP"' EXIT

if [ "$ACTION" != "status" ]; then
  if [ "$ACTION" = "on" ]; then
    # deploymentType: "all"  = 정식 주소까지 전부 잠근다
    #   ("all_except_custom_domains" 로 두면 정식 주소는 공개로 남습니다.
    #    버셀 기본값이 그것이라, 잠근 줄 알았는데 열려 있는 일이 생깁니다.)
    printf '{"ssoProtection":{"deploymentType":"all"}}' > "$TMP"
    step "사이트 잠그기 — 버셀에 로그인한 나만 접근"
  else
    printf '{"ssoProtection":null}' > "$TMP"
    step "사이트 공개하기 — 주소를 아는 누구나 접근"
  fi

  # winpath : 윈도우 프로그램인 vercel 이 읽을 수 있는 경로 형태로 변환
  vc api "/v9/projects/$NAME" -X PATCH --input "$(winpath "$TMP")" >/dev/null 2>&1 \
    || die "버셀 설정 변경 실패. 프로젝트 이름이 맞는지 확인해 주세요: $NAME"

  # 저장소 공개 범위까지 바꾸기 (--repo 를 준 경우에만)
  if [ "$ALSO_REPO" -eq 1 ]; then
    if [ "$ACTION" = "on" ]; then
      step "깃허브 저장소를 비공개로"
      "$GH" repo edit "$GH_OWNER/$NAME" --visibility private \
            --accept-visibility-change-consequences >/dev/null 2>&1 \
        || note "저장소 전환 실패 (권한 또는 이름 확인)"
    else
      step "깃허브 저장소를 공개로"
      "$GH" repo edit "$GH_OWNER/$NAME" --visibility public \
            --accept-visibility-change-consequences >/dev/null 2>&1 \
        || note "저장소 전환 실패 (권한 또는 이름 확인)"
    fi
  fi
fi

# ----------------------------------------------------------------------------
# 결과 확인 — 설정값을 믿지 않고 실제로 열어 봅니다.
#   잠겨 있으면 페이지 제목이 "Login – Vercel" 로 나옵니다.
#   이 방식이라야 "잠근 줄 알았는데 열려 있는" 상황을 잡아낼 수 있습니다.
# ----------------------------------------------------------------------------
step "로그인하지 않은 상태로 실제 접속해 확인"
SITE="$(site_url "$NAME")"

# 주소를 못 찾으면 추측하지 않습니다. 추측한 주소가 남의 사이트일 수 있어서,
# 엉뚱한 사이트 상태를 내 것인 양 보고하게 됩니다.
if [ -z "$SITE" ]; then
  SEEN=""
  STATE="배포를 찾을 수 없습니다 (아직 배포 전이거나 이름이 다를 수 있습니다)"
  SITE="—"
else
  SEEN="$(page_title "$SITE")"
  case "$SEEN" in
    *Login*) STATE="잠김 — 로그인해야 보임" ;;
    "")      STATE="응답 없음" ;;
    *)       STATE="공개 — 누구나 열림" ;;
  esac
fi

# --jq 는 실패해도 오류 본문을 stdout 으로 뱉기 때문에, 그것까지 버려야
# "(저장소 없음)" 대신 404 JSON 이 그대로 찍히는 일을 막을 수 있습니다.
REPOVIS="$("$GH" api "/repos/$GH_OWNER/$NAME" --jq .visibility 2>/dev/null)" || REPOVIS=""
[ -n "$REPOVIS" ] || REPOVIS="(저장소 없음)"

printf '\n─────────────────────────────────────────────\n'
printf ' 사이트  %s\n' "$SITE"
printf ' 상태    %s\n' "$STATE"
printf ' 보이는 제목  %s\n' "${SEEN:--}"
printf ' 저장소  %s\n' "$REPOVIS"
printf '─────────────────────────────────────────────\n'
