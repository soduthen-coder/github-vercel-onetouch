# 원터치 배포

만든 웹페이지를 **인터넷 주소로 열리게** 합니다. 명령 한 줄이면 끝납니다.

```bash
bash start.sh
```

깃허브에 올리고, 버셀로 주소를 만들고, 잘 열리는지 확인하는 것까지 한 번에 합니다.
가입만 되어 있으면 20초 걸립니다.

**설명 페이지 → https://onetouch-deploy.vercel.app**

---

## 먼저 갖춰야 할 네 가지

모두 무료입니다. 이미 있는 것은 건너뛰세요.

| | 무엇 | 받는 곳 |
|---|---|---|
| 깃허브 계정 | 파일을 보관하는 곳 | [github.com/signup](https://github.com/signup) |
| 버셀 계정 | 인터넷 주소를 만들어 주는 곳 | [vercel.com/signup](https://vercel.com/signup) |
| git | 파일을 올려 주는 프로그램 | [git-scm.com](https://git-scm.com/downloads) |
| Node.js | 배포 도구 설치에 필요 | [nodejs.org](https://nodejs.org) |

버셀은 **Continue with GitHub** 을 고르면 깃허브 계정으로 바로 가입됩니다.
2단계 인증은 설정하지 않아도 됩니다.

git 과 Node.js 는 기본 설정 그대로 설치하면 되고, 설치 후 **터미널을 껐다 켜세요.**

---

## 시작하기

윈도우는 **Git Bash**, 맥과 리눅스는 기본 터미널에서 합니다.

```bash
git clone https://github.com/soduthen-coder/github-vercel-onetouch.git
cd github-vercel-onetouch
bash start.sh
```

윈도우에서 터미널이 어렵다면 `start.cmd` 를 더블클릭해도 됩니다.

끝나면 주소가 나옵니다. 실제로 열리는지까지 확인한 결과를 함께 보여 줍니다.

---

## 그 다음

| 명령 | 하는 일 |
|---|---|
| `bash new-site.sh 이름` | 사이트를 하나 더 만듭니다 |
| `bash publish.sh "메모"` | 고친 내용을 올립니다 |
| `bash protect.sh 이름 on` | 나만 볼 수 있게 잠급니다 |
| `bash protect.sh 이름 off` | 다시 공개합니다 |
| `bash remove-site.sh 이름` | 저장소와 사이트를 지웁니다 |

이름은 한글로 줘도 됩니다. `포트폴리오` 라고 하면 저장소 이름은 `poteupolrio` 로
알아서 바꾸고, 화면에 보이는 제목은 한글 그대로 둡니다.

---

## Claude Code 를 쓴다면

저장소 주소를 붙여넣고 말로 시키면 됩니다. 명령어를 외울 필요가 없습니다.

```
"새 사이트 만들어 줘"   "고친 거 올려 줘"   "잠가 줘"   "내려 줘"
```

---

## 딱 하나만 기억하세요

**저장소를 비공개로 뒀다고 사이트까지 가려지는 것은 아닙니다.**
코드와 웹페이지는 따로 놉니다. 배포된 주소는 아는 사람이면 누구나 열 수 있습니다.

- 남에게 보여 줄 것이 아니라면 → `bash protect.sh 이름 on`
- 과제처럼 남이 열어야 한다면 → 잠그지 마세요

---

## 막히면

| 이럴 때 | 이렇게 |
|---|---|
| `git 을 찾을 수 없습니다` | git 을 설치하고 터미널을 껐다 켜세요 |
| `npm 이 없습니다` | Node.js 를 설치하세요 |
| 로그인이 안 됩니다 | 계정을 먼저 만드세요 |
| 잠갔는데 열립니다 | `bash protect.sh 이름` 으로 실제 상태를 확인하세요 |

그래도 안 되면 [이슈](https://github.com/soduthen-coder/github-vercel-onetouch/issues)에
남겨 주세요.

---

<sub>정적 사이트뿐 아니라 서버리스 함수나 Next.js 같은 프레임워크도 그대로 배포됩니다.
기본으로 만들어지는 뼈대가 단순한 것일 뿐입니다.
자세한 동작과 만들면서 부딪힌 문제들은 각 스크립트 맨 위 주석과 `CLAUDE.md` 에 적어 두었습니다.</sub>
