#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
#  Open Japan PoliTech Platform — ✨🌈🔥 マジカルセットアップスクリプト 🔥🌈✨
#  github.com/ochyai/open-japan-politech-platform
#  🏛️💎🎌 AIエージェント時代の政治インフラを、あなたの手に 🎌💎🏛️
# =============================================================================

# -- 256-color palette --------------------------------------------------------
R='\033[0m'
B='\033[1m'
D='\033[2m'
IT='\033[3m'
UL='\033[4m'
CLR='\033[K'
HIDE='\033[?25l'
SHOW='\033[?25h'

PINK='\033[38;5;213m'
HOT='\033[38;5;198m'
PURP='\033[38;5;141m'
LAVD='\033[38;5;183m'
SKY='\033[38;5;117m'
MINT='\033[38;5;121m'
PEACH='\033[38;5;216m'
GOLD='\033[38;5;220m'
GRAY='\033[38;5;245m'
DGRAY='\033[38;5;239m'
RED='\033[38;5;196m'
GRN='\033[38;5;48m'
CYN='\033[38;5;87m'
BLU='\033[38;5;33m'
WHT='\033[38;5;255m'
ORNG='\033[38;5;208m'
LIME='\033[38;5;154m'

# Brand colors
MG_COLOR='\033[38;5;33m'    # MoneyGlass  — electric blue
PD_COLOR='\033[38;5;48m'    # PolicyDiff  — neon green
PS_COLOR='\033[38;5;141m'   # ParliScope  — vivid purple
MGA_COLOR='\033[38;5;75m'   # MG Admin    — soft blue
PSA_COLOR='\033[38;5;183m'  # PS Admin    — lavender
SM_COLOR='\033[38;5;208m'   # SeatMap     — orange
CS_COLOR='\033[38;5;214m'   # CultureScope — amber/gold
SG_COLOR='\033[38;5;48m'    # SocialGuard  — emerald

# Rainbow hues
RAINBOW_HUES=(196 202 208 214 220 226 190 154 118 82 46 47 48 49 50 51 45 39 33 27 21 57 93 129 165 201 200 199 198 197)

# -- State --------------------------------------------------------------------
LOG="/tmp/ojpp-setup-$(date +%Y%m%d-%H%M%S).log"
SKIP_DOCKER=false
COMPOSE=""
TOTAL_START=$SECONDS
STEP=0
TOTAL_STEPS=15
APP_PIDS=()

# Ensure cursor is visible on exit
trap 'printf "${SHOW}"' EXIT

# ─────────────────────────────────────────────────────────────────────────────
#  Visual helpers
# ─────────────────────────────────────────────────────────────────────────────

rainbow_bar() {
  local hues=(196 202 208 214 220 226 190 154 118 82 46 48 51 39 21 57 93 129 165 201 199 197)
  echo -ne "  "
  for h in "${hues[@]}"; do printf "\033[38;5;%sm▀▀▀" "$h"; done
  echo -e "${R}"
}

rainbow_bar_block() {
  local hues=(196 202 208 214 220 226 190 154 118 82 46 48 51 39 21 57 93 129 165 201 199 197)
  echo -ne "  "
  for h in "${hues[@]}"; do printf "\033[48;5;%sm   " "$h"; done
  echo -e "${R}"
}

rainbow() {
  local text="$1"
  local hues=(196 208 220 226 46 48 51 39 21 57 129 201 199 198)
  local hi=0
  for ((i=0; i<${#text}; i++)); do
    local c="${text:$i:1}"
    if [[ "$c" == " " ]]; then
      printf " "
    else
      printf "\033[1;38;5;%sm%s" "${hues[$((hi % ${#hues[@]}))]}" "$c"
      hi=$((hi + 1))
    fi
  done
  printf "${R}"
}

rainbow_wave() {
  local text="$1"
  local offset="${2:-0}"
  local hues=(196 202 208 214 220 226 190 154 118 82 46 48 51 39 21 57 93 129 165 201)
  local hi="$offset"
  for ((i=0; i<${#text}; i++)); do
    local c="${text:$i:1}"
    if [[ "$c" == " " ]]; then
      printf " "
    else
      printf "\033[1;38;5;%sm%s" "${hues[$((hi % ${#hues[@]}))]}" "$c"
      hi=$((hi + 1))
    fi
  done
  printf "${R}"
}

draw_bar() {
  local pct="$1"
  local w=36
  local f=$((pct * w / 100))
  local e=$((w - f))
  echo -ne "\r  ${DGRAY}│${R}  "
  for ((i=0; i<f; i++)); do
    printf "\033[38;5;%sm█" "${RAINBOW_HUES[$((i % ${#RAINBOW_HUES[@]}))]}"
  done
  printf "${DGRAY}"
  for ((i=0; i<e; i++)); do printf "░"; done
  printf "${R} ${WHT}%3d%%${R}${CLR}" "$pct"
}

step_pct() {
  STEP=$((STEP + 1))
  local pct=$((STEP * 100 / TOTAL_STEPS))
  if [ "$pct" -gt 100 ]; then pct=100; fi
  draw_bar "$pct"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
#  Logging helpers  ✧  ポップで可愛い
# ─────────────────────────────────────────────────────────────────────────────
msg()     { echo -e "  ${DGRAY}│${R}  $*"; }
ok()      { echo -e "  ${DGRAY}│${R}  ${GRN}✔${R} $*${CLR}"; }
wrn()     { echo -e "  ${DGRAY}│${R}  ${GOLD}⚡${R} $*${CLR}"; }
section() { echo -e "\n  ${HOT}♦${R}  ${B}$*${R} ✨"; }

die() {
  printf "\r${SHOW}"
  echo ""
  echo -e "  ${PINK}┌─────────────────────────────────────────────────────────────${R}"
  echo -e "  ${PINK}│${R}"
  echo -e "  ${PINK}│${R}  ${HOT}(>_<)💦${R}  ${B}あわわ…うまくいかなかったよ 😭${R}"
  echo -e "  ${PINK}│${R}"
  printf  "  ${PINK}│${R}  %b\n" "$1"
  echo -e "  ${PINK}│${R}"
  echo -e "  ${PINK}│${R}  ${GRAY}📋🔎 ログ →${R} ${CYN}${LOG}${R}"
  echo -e "  ${PINK}│${R}  ${GRAY}🔄💪 もう一度 →${R} ${CYN}bash setup.sh${R} ${GRAY}（諦めないで！）${R}"
  echo -e "  ${PINK}│${R}"
  echo -e "  ${PINK}└─────────────────────────────────────────────────────────────${R}"
  echo ""
  exit 1
}

run_spin() {
  local label="$1"; shift
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local colors=(196 208 220 46 51 21 129 201)
  local idx=0 t=$SECONDS

  printf "${HIDE}"
  "$@" >> "$LOG" 2>&1 &
  local cmd_pid=$!

  while kill -0 "$cmd_pid" 2>/dev/null; do
    local col="${colors[$((idx % ${#colors[@]}))]}"
    printf "\r  ${DGRAY}│${R}  \033[38;5;%sm%s${R} %s${CLR}" "$col" "${frames[$((idx % ${#frames[@]}))]}" "$label"
    idx=$((idx + 1))
    sleep 0.08
  done

  wait "$cmd_pid" 2>/dev/null
  local rc=$?
  printf "${SHOW}"
  local dt=$((SECONDS - t))
  local ts=""
  if [ "$dt" -gt 2 ]; then ts=" ${GRAY}(${dt}s)${R}"; fi

  if [ "$rc" -eq 0 ]; then
    printf "\r  ${DGRAY}│${R}  ${GRN}✔${R} %b%b${CLR}\n" "$label" "$ts"
  else
    printf "\r  ${DGRAY}│${R}  ${RED}✖${R} %s${CLR}\n" "$label"
  fi
  return "$rc"
}

# ─────────────────────────────────────────────────────────────────────────────
#  Port helpers
# ─────────────────────────────────────────────────────────────────────────────

port_in_use() {
  (echo >/dev/tcp/localhost/"$1") 2>/dev/null
}

find_free_port() {
  local port=$1
  while port_in_use "$port"; do
    port=$((port + 1))
  done
  echo "$port"
}

kill_ports() {
  for p in "$@"; do
    local pids
    pids=$(lsof -ti :"$p" 2>/dev/null || true)
    if [ -n "$pids" ]; then
      echo "$pids" | xargs kill -9 2>/dev/null || true
    fi
  done
  sleep 0.5
}

# =============================================================================
#  🌈 BANNER
# =============================================================================
clear 2>/dev/null || true
echo ""
rainbow_bar_block
echo ""
echo ""

echo -e "  \033[38;5;196m  ██████╗ \033[38;5;208m     ██╗\033[38;5;220m██████╗ \033[38;5;226m██████╗ ${R}"
echo -e "  \033[38;5;196m ██╔═══██╗\033[38;5;208m     ██║\033[38;5;220m██╔══██╗\033[38;5;226m██╔══██╗${R}"
echo -e "  \033[38;5;46m ██║   ██║\033[38;5;48m     ██║\033[38;5;51m██████╔╝\033[38;5;39m██████╔╝${R}"
echo -e "  \033[38;5;46m ██║   ██║\033[38;5;48m██   ██║\033[38;5;51m██╔═══╝ \033[38;5;39m██╔═══╝ ${R}"
echo -e "  \033[38;5;129m ╚██████╔╝\033[38;5;165m╚█████╔╝\033[38;5;201m██║     \033[38;5;198m██║     ${R}"
echo -e "  \033[38;5;129m  ╚═════╝ \033[38;5;165m ╚════╝ \033[38;5;201m╚═╝     \033[38;5;198m╚═╝     ${R}"

echo ""
echo -ne "  "; rainbow "Open Japan PoliTech Platform"; echo -e "  ${DGRAY}v0.1.1${R}"
echo ""
echo -e "  ${LAVD}🏛️✨ ${B}AIエージェント時代の政治インフラ${R} ${PINK}*:${R}${HOT}.${R}${GOLD}*${R}${PINK}｡${R}${HOT}･ﾟ${R}${GOLD}✧${R}"
echo -e "  ${GRAY}🌏 政党にも企業にもよらない、完全オープンな政治テクノロジー基盤 💫${R}"
echo -e "  ${MG_COLOR}${B}💰MoneyGlass${R}${DGRAY} · ${PD_COLOR}${B}📜PolicyDiff${R}${DGRAY} · ${PS_COLOR}${B}🏛️ParliScope${R}${DGRAY} · ${SM_COLOR}${B}💺SeatMap${R}${DGRAY} · ${CS_COLOR}${B}🎨CultureScope${R}${DGRAY} · ${SG_COLOR}${B}🛡️SocialGuard${R}"
echo -e "  ${GRAY}🔥 6つのアプリで日本の政治を丸ごと可視化 — 15政党・47都道府県対応 🎌🇯🇵${R}"
echo ""
rainbow_bar_block
echo ""

# Sanity check
grep -q "open-japan-politech-platform" package.json 2>/dev/null \
  || die "ここは OJPP のディレクトリじゃないみたい…\n     ${CYN}cd open-japan-politech-platform && bash setup.sh${R} してね♪"

# =============================================================================
#  0. Homebrew  (macOS のみ — brew がなければ自動インストール)
# =============================================================================
if [[ "$OSTYPE" == darwin* ]] && ! command -v brew &>/dev/null; then
  section "🍺🎉 Homebrew セットアップ ～はじめの一歩だよ～ ﾄﾞｷﾄﾞｷ"
  echo ""
  echo -e "  ${PEACH}┌───────────────────────────────────────────────────────────${R}"
  echo -e "  ${PEACH}│${R}  ${B}🍺 Homebrew が見つからないよ！${R}"
  echo -e "  ${PEACH}│${R}  ${GRAY}macOS のパッケージマネージャーを自動インストールするね${R}"
  echo -e "  ${PEACH}│${R}  ${GOLD}🔑 sudo パスワードを聞かれたら入力してね${R}"
  echo -e "  ${PEACH}└───────────────────────────────────────────────────────────${R}"
  echo ""

  # NONINTERACTIVE=1 → "Press RETURN" プロンプトをスキップ
  # sudo は直接ターミナルからパスワードを聞く
  if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    # Apple Silicon or Intel — PATH を通す
    if [ -x "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi

    if command -v brew &>/dev/null; then
      echo ""
      ok "🍺🎊 Homebrew インストール完了！やったね！ﾔｯﾎｰ！✨"
    else
      die "Homebrew の PATH が通らなかった…\n     ターミナルを再起動して ${CYN}bash setup.sh${R} してみて"
    fi
  else
    die "Homebrew のインストールに失敗しちゃった…\n     ${CYN}https://brew.sh${R} から手動でインストールしてみてね"
  fi
fi

# =============================================================================
#  1. Podman  ～コンテナの魔法使い～
# =============================================================================
section "🔍💎 まずは環境チェックだよ！ (ﾟ∀ﾟ)"
draw_bar 0
echo ""

install_podman_mac() {
  echo ""
  echo -e "  ${SKY}┌───────────────────────────────────────────────────────────${R}"
  echo -e "  ${SKY}│${R}  ${B}🐳 Podman をインストールするよ！${R}"
  echo -e "  ${SKY}│${R}  ${GRAY}brew でダウンロード (~1 GB)${R} ${PEACH}ちょっとだけ待ってね ☕${R}"
  echo -e "  ${SKY}│${R}  ${GRAY}↓ 進捗がリアルタイムで見えるよ${R}"
  echo -e "  ${SKY}└───────────────────────────────────────────────────────────${R}"
  echo ""

  # Show brew output directly — progress bar 見せる！
  if brew install --cask podman 2>&1 | while IFS= read -r line; do
      echo -e "  ${DGRAY}│${R}  ${GRAY}${line}${R}"
    done; then
    echo ""
    ok "🐳🎉💯 Podman インストール完了！すごい！ｸｼﾞﾗさんきた！"
    echo ""
    echo -e "  ${GOLD}┌───────────────────────────────────────────────────────────${R}"
    echo -e "  ${GOLD}│${R}"
    echo -e "  ${GOLD}│${R}  ${B}🐳 Podman がインストールできたよ！${R}"
    echo -e "  ${GOLD}│${R}"
    echo -e "  ${GOLD}│${R}  ${WHT}あと少し！次の2ステップだけ：${R}"
    echo -e "  ${GOLD}│${R}"
    echo -e "  ${GOLD}│${R}  ${GOLD}①${R} メニューバー右上のクジラ 🐳 マークをクリック"
    echo -e "  ${GOLD}│${R}"
    echo -e "  ${GOLD}│${R}  ${GOLD}②${R} 下のコマンドをコピペして実行してね："
    echo -e "  ${GOLD}│${R}"
    echo -e "  ${GOLD}│${R}     ${CYN}bash setup.sh${R}"
    echo -e "  ${GOLD}│${R}"
    echo -e "  ${GOLD}│${R}  ${GRAY}（クジラマークが見えなかったら少し待ってね 30秒くらい）${R}"
    echo -e "  ${GOLD}│${R}"
    echo -e "  ${GOLD}└───────────────────────────────────────────────────────────${R}"
    echo ""
    rainbow_bar
    echo ""
    exit 0
  else
    return 1
  fi
}

if ! command -v podman &>/dev/null; then
  if [[ "$OSTYPE" == darwin* ]] && command -v brew &>/dev/null; then
    msg "${SKY}🍺 Homebrew 検出！Podman を自動インストールするね${R}"
    install_podman_mac || die "Podman のインストールに失敗しちゃった…\n     ${CYN}brew install --cask podman${R} を手動で試してみて"
  elif [[ "$OSTYPE" == darwin* ]]; then
    echo ""
    echo -e "  ${PINK}┌───────────────────────────────────────────────────────────${R}"
    echo -e "  ${PINK}│${R}  ${B}🐳 Podman が必要だよ！${R}"
    echo -e "  ${PINK}│${R}  ${CYN}  brew install --cask podman${R}"
    echo -e "  ${PINK}│${R}  ${WHT}or${R} ${CYN}https://podman.io/getting-started/installation${R}"
    echo -e "  ${PINK}│${R}  インストールしたら → ${CYN}bash setup.sh${R}"
    echo -e "  ${PINK}└───────────────────────────────────────────────────────────${R}"
    echo ""; exit 1
  else
    echo ""
    echo -e "  ${PINK}┌───────────────────────────────────────────────────────────${R}"
    echo -e "  ${PINK}│${R}  ${B}🐳 Podman が必要だよ！${R}"
    echo -e "  ${PINK}│${R}  ${CYN}  https://podman.io/getting-started/installation${R}"
    echo -e "  ${PINK}│${R}  インストールしたら → ${CYN}bash setup.sh${R}"
    echo -e "  ${PINK}└───────────────────────────────────────────────────────────${R}"
    echo ""; exit 1
  fi
fi

# Podman daemon — auto-start on macOS
if ! podman info >> "$LOG" 2>&1; then
  if [[ "$OSTYPE" == darwin* ]]; then
    msg "${SKY}🐳 Podman をよいしょっと起動...${R}"
    open -a Podman 2>/dev/null || true
    _fi=0; _start=$SECONDS
    _frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    printf "${HIDE}"
    while ! podman info >> "$LOG" 2>&1; do
      _e=$((SECONDS - _start))
      printf "\r  ${DGRAY}│${R}  \033[38;5;%sm%s${R} 🐳 Podman が目を覚ますのを待ってるよ... ${GRAY}(%ds)${R}${CLR}" \
        "${RAINBOW_HUES[$((_fi % ${#RAINBOW_HUES[@]}))]}" \
        "${_frames[$((_fi % 10))]}" "$_e"
      _fi=$((_fi + 1))
      sleep 1
      if [ "$_e" -gt 60 ]; then
        printf "${SHOW}\r  ${DGRAY}│${R}  ${GOLD}⚡${R} 60秒待ったけどまだ…リカバリーしてみるね！${CLR}\n"

        # Recovery step 1: Remove quarantine attribute (malware block)
        msg "${SKY}🔧 セキュリティブロックを解除してみるよ...${R}"
        xattr -cr /Applications/Podman.app 2>/dev/null || true

        # Recovery step 2: Kill all Podman processes
        msg "${SKY}🔧 Podman プロセスを全部止めて再起動するね...${R}"
        killall Podman 2>/dev/null || true
        killall com.podman.vmnetd 2>/dev/null || true
        sleep 2

        # Recovery step 3: Restart Podman
        open -a Podman 2>/dev/null || true

        # Recovery step 4: Wait another 45 seconds
        _fi2=0; _start2=$SECONDS
        printf "${HIDE}"
        _podman_ok=false
        while [ $((SECONDS - _start2)) -lt 45 ]; do
          _e2=$((SECONDS - _start2))
          printf "\r  ${DGRAY}│${R}  \033[38;5;%sm%s${R} 🐳 リカバリー中...もうちょっと待ってね ${GRAY}(%ds/45s)${R}${CLR}" \
            "${RAINBOW_HUES[$((_fi2 % ${#RAINBOW_HUES[@]}))]}" \
            "${_frames[$((_fi2 % 10))]}" "$_e2"
          _fi2=$((_fi2 + 1))
          if podman info >> "$LOG" 2>&1; then
            _podman_ok=true
            break
          fi
          sleep 1
        done
        printf "${SHOW}"

        if [ "$_podman_ok" = true ]; then
          printf "\r  ${DGRAY}│${R}  ${GRN}✔${R} 🐳 リカバリー成功！Podman 起きたよ！${CLR}\n"
          break
        fi

        # Recovery step 5: If brew is available, try reinstalling Podman
        if command -v brew &>/dev/null; then
          echo ""
          msg "${GOLD}🍺 brew で Podman を再インストールしてみるね...${R}"
          killall Podman 2>/dev/null || true
          sleep 1
          if brew reinstall --cask podman 2>&1 | while IFS= read -r line; do
              echo -e "  ${DGRAY}│${R}  ${GRAY}${line}${R}"
            done; then
            ok "Podman 再インストール完了！起動するね..."

            # Recovery step 6: Start Podman after reinstall, wait 60s
            open -a Podman 2>/dev/null || true
            _fi3=0; _start3=$SECONDS
            printf "${HIDE}"
            _podman_ok2=false
            while [ $((SECONDS - _start3)) -lt 60 ]; do
              _e3=$((SECONDS - _start3))
              printf "\r  ${DGRAY}│${R}  \033[38;5;%sm%s${R} 🐳 再インストール後の起動待ち... ${GRAY}(%ds/60s)${R}${CLR}" \
                "${RAINBOW_HUES[$((_fi3 % ${#RAINBOW_HUES[@]}))]}" \
                "${_frames[$((_fi3 % 10))]}" "$_e3"
              _fi3=$((_fi3 + 1))
              if podman info >> "$LOG" 2>&1; then
                _podman_ok2=true
                break
              fi
              sleep 1
            done
            printf "${SHOW}"

            if [ "$_podman_ok2" = true ]; then
              printf "\r  ${DGRAY}│${R}  ${GRN}✔${R} 🐳 再インストール後の起動成功！やったね！${CLR}\n"
              break
            fi
          fi
        fi

        # Recovery step 7: All recovery failed — show super friendly error
        echo ""
        echo -e "  ${PINK}┌───────────────────────────────────────────────────────────${R}"
        echo -e "  ${PINK}│${R}"
        echo -e "  ${PINK}│${R}  ${HOT}(>_<)${R}  ${B}Podman がどうしても起きてくれない...${R}"
        echo -e "  ${PINK}│${R}"
        echo -e "  ${PINK}│${R}  ${WHT}こうしてみてね（かんたん3ステップ）:${R}"
        echo -e "  ${PINK}│${R}"
        echo -e "  ${PINK}│${R}  ${GOLD}①${R} Podman Desktop アプリを手動で開いてみて"
        echo -e "  ${PINK}│${R}     ${GRAY}Finder → アプリケーション → Podman をダブルクリック${R}"
        echo -e "  ${PINK}│${R}"
        echo -e "  ${PINK}│${R}  ${GOLD}②${R} 画面右上のメニューバーに 🐳 クジラが出るまで待ってね"
        echo -e "  ${PINK}│${R}     ${GRAY}（30秒〜1分くらいかかるよ）${R}"
        echo -e "  ${PINK}│${R}"
        echo -e "  ${PINK}│${R}  ${GOLD}③${R} クジラが出たらこのコマンドをもう一回："
        echo -e "  ${PINK}│${R}     ${CYN}bash setup.sh${R}"
        echo -e "  ${PINK}│${R}"
        echo -e "  ${PINK}│${R}  ${GRAY}💡 それでもダメなら:${R}"
        echo -e "  ${PINK}│${R}  ${GRAY}   Mac を再起動してからもう一度やってみてね${R}"
        echo -e "  ${PINK}│${R}"
        echo -e "  ${PINK}│${R}  ${GRAY}📋 ログ →${R} ${CYN}${LOG}${R}"
        echo -e "  ${PINK}│${R}"
        echo -e "  ${PINK}└───────────────────────────────────────────────────────────${R}"
        echo ""
        exit 1
      fi
    done
    printf "${SHOW}\r  ${DGRAY}│${R}  ${GRN}✔${R} 🐳☀️ Podman 起きた！おはよう！ﾑｸﾘ！${CLR}\n"
  else
    die "Podman が起動してないよ\n     ${CYN}sudo systemctl start podman${R}"
  fi
fi

if command -v podman-compose &>/dev/null; then
  COMPOSE="podman-compose"
else
  COMPOSE="podman compose"
  if ! $COMPOSE version >> "$LOG" 2>&1; then
    die "podman compose が見つからないよ…"
  fi
  export PODMAN_COMPOSE_PROVIDER="podman-compose"
fi
COMPOSE_HINT="$COMPOSE"
PODMAN_VER=$(podman --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | /usr/bin/head -1)
ok "🐳✨ Podman ${PODMAN_VER} — いい感じ！ﾖｼ！"
step_pct

# =============================================================================
#  2. Node.js  ～JavaScriptの心臓～
# =============================================================================

install_node() {
  if command -v fnm &>/dev/null; then
    fnm install 22 >> "$LOG" 2>&1 && eval "$(fnm env)" && fnm use 22 >> "$LOG" 2>&1
  elif [ -s "$HOME/.nvm/nvm.sh" ]; then
    . "$HOME/.nvm/nvm.sh"; nvm install 22 >> "$LOG" 2>&1 && nvm use 22 >> "$LOG" 2>&1
  elif command -v mise &>/dev/null; then
    mise install node@22 >> "$LOG" 2>&1 && eval "$(mise activate bash)" && mise use --env local node@22 >> "$LOG" 2>&1
  else
    run_spin "⬇️ fnm をインストール" bash -c "curl -fsSL https://fnm.vercel.app/install 2>/dev/null | bash -s -- --skip-shell >> '$LOG' 2>&1" || true
    FNM_DIR="${FNM_DIR:-$HOME/.local/share/fnm}"; [ -d "$FNM_DIR" ] || FNM_DIR="$HOME/.fnm"
    export PATH="$FNM_DIR:$PATH"
    eval "$(fnm env 2>/dev/null)" || eval "$("$FNM_DIR/fnm" env 2>/dev/null)"
    run_spin "💚 Node.js 22 をインストール" bash -c "fnm install 22 >> '$LOG' 2>&1 && fnm use 22 >> '$LOG' 2>&1"
  fi
}

if command -v node &>/dev/null; then
  NODE_MAJOR=$(node -v | sed 's/v//' | cut -d. -f1)
  if [ "$NODE_MAJOR" -ge 22 ]; then
    ok "💚🚀 Node.js $(node -v) — バッチリ！最高！(☆▽☆)"
  else
    wrn "Node $(node -v) → v22+ にアップグレード中 🔄"
    install_node
    ok "💚⬆️ Node.js $(node -v) — アップグレード完了！ﾔｯﾀｰ！"
  fi
else
  msg "${SKY}💚📦 Node.js を自動インストールするね${R}"
  install_node
  ok "💚🆕 Node.js $(node -v) — ピカピカの新品！✨"
fi
step_pct

# =============================================================================
#  3. pnpm  ～高速パッケージマネージャー～
# =============================================================================

if ! command -v pnpm &>/dev/null; then
  if command -v corepack &>/dev/null; then
    run_spin "📦 pnpm をインストール" bash -c "corepack enable >> '$LOG' 2>&1; corepack prepare pnpm@10.4.0 --activate >> '$LOG' 2>&1 || npm install -g pnpm@10 >> '$LOG' 2>&1"
  else
    run_spin "📦 pnpm をインストール" npm install -g pnpm@10
  fi
fi
ok "📦💨 pnpm $(pnpm --version) — 爆速パッケージマネージャー！ﾋﾞｭﾝﾋﾞｭﾝ！"
step_pct

# =============================================================================
#  3.5. Entire CLI  ～AIの記憶を紡ぐ者～  【オプション・失敗しても続行】
# =============================================================================
section "🧠💫 Entire CLI ～AIエージェントの思考を共有する魔法～ (◕‿◕✿)"

ENTIRE_OK=false

install_entire() {
  if [[ "$OSTYPE" == darwin* ]] && command -v brew &>/dev/null; then
    # macOS + Homebrew: tap & install
    run_spin "🧠 Entire CLI をインストール (brew)" bash -c \
      "brew tap entireio/tap >> '$LOG' 2>&1 && brew install entireio/tap/entire >> '$LOG' 2>&1" \
      && return 0
  fi
  # Linux / WSL / Homebrew がない場合: curl installer
  run_spin "🧠 Entire CLI をインストール (curl)" bash -c \
    "curl -fsSL https://entire.io/install.sh 2>/dev/null | bash >> '$LOG' 2>&1" \
    && return 0
  return 1
}

enable_entire() {
  # .entire/settings.json が既にリポジトリにあるので --force でフック再インストール
  # --project で共有設定を使用、--agent claude-code でClaude Code対応
  if entire enable --force --agent claude-code --strategy manual-commit --project >> "$LOG" 2>&1; then
    return 0
  fi
  return 1
}

if command -v entire &>/dev/null; then
  ENTIRE_VER=$(entire version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | /usr/bin/head -1 || echo "?")
  ok "🧠✨ Entire ${ENTIRE_VER} — もう入ってるね！ﾃﾞｷﾙ子！"
  if enable_entire; then
    ENTIRE_OK=true
    ok "🧠🔗 Entire Git フック設定完了！エージェントの思考が記録されるよ ✨"
  else
    wrn "Entire のフック設定をスキップ（手動で ${CYN}entire enable${R} してね）"
  fi
elif [[ "$OSTYPE" == darwin* ]] && command -v brew &>/dev/null; then
  # macOS + Homebrew がある → 自動インストール試行
  msg "${SKY}🧠 Entire CLI（AIセッション共有ツール）を自動インストールするね${R}"
  if install_entire && command -v entire &>/dev/null; then
    ENTIRE_VER=$(entire version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | /usr/bin/head -1 || echo "?")
    ok "🧠🎉 Entire ${ENTIRE_VER} — インストール完了！ﾔｯﾀ！"
    if enable_entire; then
      ENTIRE_OK=true
      ok "🧠🔗 Entire Git フック設定完了！エージェントの思考が記録されるよ ✨"
    else
      wrn "Entire のフック設定をスキップ（手動で ${CYN}entire enable${R} してね）"
    fi
  else
    echo ""
    echo -e "  ${LAVD}┌───────────────────────────────────────────────────────────${R}"
    echo -e "  ${LAVD}│${R}  ${B}🧠 Entire CLI のインストールをスキップしたよ${R}"
    echo -e "  ${LAVD}│${R}"
    echo -e "  ${LAVD}│${R}  ${GRAY}これはオプションのツールだよ♪ なくても全然大丈夫！${R}"
    echo -e "  ${LAVD}│${R}  ${GRAY}あとで入れたくなったら:${R}"
    echo -e "  ${LAVD}│${R}  ${CYN}  brew tap entireio/tap && brew install entireio/tap/entire${R}"
    echo -e "  ${LAVD}│${R}  ${CYN}  entire enable${R}"
    echo -e "  ${LAVD}│${R}"
    echo -e "  ${LAVD}│${R}  ${GRAY}💡 AIエージェントの思考プロセスをGitで共有できるよ${R}"
    echo -e "  ${LAVD}└───────────────────────────────────────────────────────────${R}"
    echo ""
  fi
else
  # Homebrew がない Linux 等 → curl で試行
  msg "${SKY}🧠 Entire CLI（AIセッション共有ツール）を自動インストールするね${R}"
  if install_entire && command -v entire &>/dev/null; then
    ENTIRE_VER=$(entire version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | /usr/bin/head -1 || echo "?")
    ok "🧠🎉 Entire ${ENTIRE_VER} — インストール完了！ﾔｯﾀ！"
    if enable_entire; then
      ENTIRE_OK=true
      ok "🧠🔗 Entire Git フック設定完了！エージェントの思考が記録されるよ ✨"
    else
      wrn "Entire のフック設定をスキップ（手動で ${CYN}entire enable${R} してね）"
    fi
  else
    echo ""
    echo -e "  ${LAVD}┌───────────────────────────────────────────────────────────${R}"
    echo -e "  ${LAVD}│${R}  ${B}🧠 Entire CLI のインストールをスキップしたよ${R}"
    echo -e "  ${LAVD}│${R}"
    echo -e "  ${LAVD}│${R}  ${GRAY}これはオプションのツールだよ♪ なくても全然大丈夫！${R}"
    echo -e "  ${LAVD}│${R}  ${GRAY}あとで入れたくなったら:${R}"
    echo -e "  ${LAVD}│${R}  ${CYN}  curl -fsSL https://entire.io/install.sh | bash${R}"
    echo -e "  ${LAVD}│${R}  ${CYN}  entire enable${R}"
    echo -e "  ${LAVD}│${R}"
    echo -e "  ${LAVD}│${R}  ${GRAY}💡 AIエージェントの思考プロセスをGitで共有できるよ${R}"
    echo -e "  ${LAVD}└───────────────────────────────────────────────────────────${R}"
    echo ""
  fi
fi
step_pct

# =============================================================================
#  4. PostgreSQL  ～データの守護者～
# =============================================================================
section "🐘💾 データベースをセットアップ ～ここ大事！～ (｀・ω・´)ゞ"

if port_in_use 54322; then
  ok "🐘🎯 既存 PostgreSQL 発見 (localhost:54322) → そのまま使うよ！ﾅｲｽ！"
  SKIP_DOCKER=true
else
  run_spin "🐘 PostgreSQL 16 コンテナを召喚" $COMPOSE up -d db \
    || die "PostgreSQL の起動に失敗しちゃった…"
  _fi=0
  printf "${HIDE}"
  _pg_frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  for attempt in $(seq 1 30); do
    printf "\r  ${DGRAY}│${R}  ${SKY}%s${R} 🐘 PostgreSQL の準備を待ってるよ...${CLR}" "${_pg_frames[$((_fi % 10))]}"
    _fi=$((_fi + 1))
    if $COMPOSE exec -T db pg_isready -U postgres >> "$LOG" 2>&1; then
      printf "${SHOW}\r  ${DGRAY}│${R}  ${GRN}✔${R} 🐘 PostgreSQL 起動完了！象さん元気！${CLR}\n"
      break
    fi
    sleep 0.5
    if [ "$attempt" -eq 30 ]; then printf "${SHOW}"; die "PostgreSQL タイムアウト…象さんが起きない"; fi
  done
fi
step_pct

# =============================================================================
#  5. .env + environment variables  ～秘密の設定ファイル～
# =============================================================================
section "📦🎁 依存関係をぜんぶ入れちゃうぞ！ﾓﾘﾓﾘ！"

if [ ! -f .env ]; then
  cp .env.example .env
  ok "📝✏️ .env を作成したよ！秘密の設定ファイル完成 🔐"
else
  ok "📝👌 .env はもうあるね（上書きしないよ♪）"
fi

# CRITICAL: Export all env vars so child processes (Next.js, Prisma) can see them
set -a
source .env
set +a

# Also symlink .env into each app directory — Next.js reads .env from CWD only
for app_dir in apps/*/; do
  if [ -d "$app_dir" ] && [ ! -e "${app_dir}.env" ]; then
    ln -sf "../../.env" "${app_dir}.env"
  fi
done
ok "🔗💌 環境変数を全8アプリに配布完了！(DATABASE_URL etc.) ﾊﾞｯﾁﾘ！"
step_pct

# =============================================================================
#  6. pnpm install  ～パッケージもりもりタイム～
# =============================================================================

run_spin "📦🍱 パッケージをもりもりインストール中...ﾜｸﾜｸ" pnpm install \
  || die "pnpm install に失敗しちゃった…😭\n     ${GRAY}ログ: $LOG${R}"
step_pct

# =============================================================================
#  7. Database schema + seed  ～データの種まき～
# =============================================================================
section "🗄️🌊 データベースにデータを流し込むよ！ｻﾞﾊﾞｰ！"

run_spin "⚡💫 Prisma Client をシャキッと生成！ﾋﾟｶｯ！" pnpm db:generate \
  || die "Prisma Client の生成に失敗しちゃった…😭"

run_spin "🗄️📝 スキーマを DB に書き込み！ｶﾞﾘｶﾞﾘ！" pnpm --filter @ojpp/db push \
  || die "スキーマの反映に失敗…😢\n     ${GRAY}DATABASE_URL を確認してみて${R}"
step_pct

if run_spin "🌱🎌 初期データをたっぷり投入！(15政党・47都道府県・713議員) ﾄﾞｻﾄﾞｻ！" pnpm db:seed; then :
else wrn "スキップ（もうデータ入ってるみたい 👌）"; fi

if run_spin "📊🏛️ 政治データをごっそり取り込み！(資金・議会・政策・文化・社保) ﾊﾞﾘﾊﾞﾘ！" pnpm ingest:all; then :
else wrn "スキップ（もうデータ入ってるみたい 👌）"; fi
step_pct

# =============================================================================
#  7.5. DB connection verification  ～接続チェック～
# =============================================================================
section "🔍🔌 データベース接続を最終チェック！ﾄﾞｷﾄﾞｷ..."

# Verify Prisma can actually connect and query data
DB_CHECK_SCRIPT='
const { PrismaClient } = require("@prisma/client");
const p = new PrismaClient();
p.election.count().then(c => { console.log("elections:" + c); p.$disconnect(); }).catch(e => { console.error(e.message); process.exit(1); });
'
if node -e "$DB_CHECK_SCRIPT" >> "$LOG" 2>&1; then
  ok "🔗✅ Prisma → PostgreSQL 接続OK！データも確認済み！ﾊﾟｰﾌｪｸﾄ！"
else
  wrn "Prisma 接続に問題あり — 念のため接続をリセットするね"
  # Kill idle connections to free slots (use podman compose exec to auto-resolve container name)
  $COMPOSE exec -T db psql -U postgres -d postgres \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND pid <> pg_backend_pid();" \
    >> "$LOG" 2>&1 || true
  sleep 1
  if node -e "$DB_CHECK_SCRIPT" >> "$LOG" 2>&1; then
    ok "🔗 リセット後の接続OK！"
  else
    wrn "DB接続の問題が続いています — アプリ起動後にリトライします"
  fi
fi
step_pct

# =============================================================================
#  8. Clean caches + find free ports + start apps  ～いよいよ起動！～
# =============================================================================
section "🚀🔥💥 アプリをぜんぶ起動するよ！ﾜｸﾜｸが止まらない！(ﾉ◕ヮ◕)ﾉ*:・ﾟ✧"

# Clean stale caches
run_spin "🧹✨ キャッシュをピカピカにお掃除！ﾋﾟｯｶﾋﾟｶ！" bash -c "rm -rf apps/*/.next apps/*/.turbo .turbo node_modules/.cache 2>/dev/null; echo ok"

# Kill any leftover OJPP processes on default ports
kill_ports 3000 3001 3002 3003 3004 3005 3006 3007
sleep 0.5

# Find 8 free ports — auto-assign if defaults are occupied
PORT_MG=$(find_free_port 3000)
PORT_MGA=$(find_free_port $((PORT_MG + 1)))
PORT_PD=$(find_free_port $((PORT_MGA + 1)))
PORT_PS=$(find_free_port $((PORT_PD + 1)))
PORT_PSA=$(find_free_port $((PORT_PS + 1)))
PORT_SM=$(find_free_port $((PORT_PSA + 1)))
PORT_CS=$(find_free_port $((PORT_SM + 1)))
PORT_SG=$(find_free_port $((PORT_CS + 1)))

if [ "$PORT_MG" -ne 3000 ] || [ "$PORT_MGA" -ne 3001 ] || [ "$PORT_PD" -ne 3002 ] || [ "$PORT_PS" -ne 3003 ] || [ "$PORT_PSA" -ne 3004 ] || [ "$PORT_SM" -ne 3005 ] || [ "$PORT_CS" -ne 3006 ] || [ "$PORT_SG" -ne 3007 ]; then
  wrn "一部のポートが使用中 → 空いてるポートを見つけたよ！"
fi

ok "🎯 ポート割り当て: ${CYN}${PORT_MG}${R} ${CYN}${PORT_MGA}${R} ${CYN}${PORT_PD}${R} ${CYN}${PORT_PS}${R} ${CYN}${PORT_PSA}${R} ${CYN}${PORT_SM}${R} ${CYN}${PORT_CS}${R} ${CYN}${PORT_SG}${R}"

# Start each Next.js app individually with the assigned port
NEXT_BIN=""
if [ -f "apps/moneyglass-web/node_modules/.bin/next" ]; then
  NEXT_BIN="node_modules/.bin/next"
elif [ -f "node_modules/.bin/next" ]; then
  NEXT_BIN="../../node_modules/.bin/next"
fi

start_one_app() {
  local dir="$1" port="$2" name="$3"
  local log="/tmp/ojpp-${name}-$(date +%s).log"
  if [ -n "$NEXT_BIN" ]; then
    (cd "$dir" && exec "$NEXT_BIN" dev --port "$port") > "$log" 2>&1 &
  else
    (cd "$dir" && PATH="./node_modules/.bin:../../node_modules/.bin:$PATH" exec next dev --port "$port") > "$log" 2>&1 &
  fi
  APP_PIDS+=($!)
}

start_all_apps() {
  APP_PIDS=()
  start_one_app "apps/moneyglass-web"   "$PORT_MG"  "mg-web"
  start_one_app "apps/moneyglass-admin"  "$PORT_MGA" "mg-admin"
  start_one_app "apps/policydiff-web"    "$PORT_PD"  "pd-web"
  start_one_app "apps/parliscope-web"    "$PORT_PS"  "ps-web"
  start_one_app "apps/parliscope-admin"  "$PORT_PSA" "ps-admin"
  [ -d "apps/seatmap-web" ]       && start_one_app "apps/seatmap-web"       "$PORT_SM" "sm-web"
  [ -d "apps/culturescope-web" ]  && start_one_app "apps/culturescope-web"  "$PORT_CS" "cs-web"
  [ -d "apps/socialguard-web" ]   && start_one_app "apps/socialguard-web"   "$PORT_SG" "sg-web"
}

start_all_apps

# Cleanup handler — kill all app processes + release ports
cleanup() {
  printf "${SHOW}\n"
  printf "  ${PINK}♦${R}  停止中...\r"
  for pid in "${APP_PIDS[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  for pid in "${APP_PIDS[@]}"; do
    wait "$pid" 2>/dev/null || true
  done
  kill_ports "$PORT_MG" "$PORT_MGA" "$PORT_PD" "$PORT_PS" "$PORT_PSA" "$PORT_SM" "$PORT_CS" "$PORT_SG"
  if [ "$SKIP_DOCKER" = false ]; then
    $COMPOSE down >> "$LOG" 2>&1 || true
  fi
  echo ""
  echo -e "  ${PINK}♦${R}  ${B}おつかれさまでした！🙏✨${R} ${PEACH}またね♪${R} ${GRAY}(^_^)/~ 👋🌸${R}"
  echo ""
}
trap cleanup INT TERM

msg "${GRAY}☕🍵 初回コンパイル中...ちょっとだけ待ってね ﾎﾟｯ${R}"

# Wait for each public app to be ready
RETRY_DONE=false

any_app_alive() {
  for pid in "${APP_PIDS[@]}"; do
    kill -0 "$pid" 2>/dev/null && return 0
  done
  return 1
}

wait_for_app() {
  local port=$1 name=$2 emoji=$3 color=$4
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local _f=0 start=$SECONDS

  printf "${HIDE}"
  while true; do
    local col_i=$((_f % ${#RAINBOW_HUES[@]}))
    printf "\r  ${DGRAY}│${R}  \033[38;5;%sm%s${R} %s を起動中...${CLR}" \
      "${RAINBOW_HUES[$col_i]}" "${frames[$((_f % 10))]}" "$name"
    _f=$((_f + 1))

    if curl -sf -o /dev/null --max-time 0.5 "http://localhost:$port" 2>/dev/null; then
      local dt=$((SECONDS - start))
      local ts=""
      if [ "$dt" -gt 3 ]; then ts=" ${GRAY}(${dt}s)${R}"; fi
      printf "${SHOW}\r  ${DGRAY}│${R}  ${GRN}✔${R} %s ${color}${B}%s${R} → ${CYN}localhost:%s${R}%b${CLR}\n" "$emoji" "$name" "$port" "$ts"
      return 0
    fi

    # All processes dead — retry once
    if ! any_app_alive; then
      if [ "$RETRY_DONE" = false ]; then
        RETRY_DONE=true
        printf "${SHOW}\r  ${DGRAY}│${R}  ${GOLD}⚡${R} アプリ再起動するね...ちょっと待って${CLR}\n"
        rm -rf apps/*/.next 2>/dev/null || true
        kill_ports "$PORT_MG" "$PORT_MGA" "$PORT_PD" "$PORT_PS" "$PORT_PSA" "$PORT_SM" "$PORT_CS" "$PORT_SG"
        sleep 1
        start_all_apps
        sleep 2
        start=$SECONDS
        _f=0
        printf "${HIDE}"
        continue
      fi
      printf "${SHOW}\r  ${DGRAY}│${R}  ${RED}✖${R} %s${CLR}\n" "$name"
      die "全アプリが落ちちゃった…\n     ${GRAY}ログ: /tmp/ojpp-*.log を見てみて${R}"
    fi

    if [ $((SECONDS - start)) -gt 120 ]; then
      printf "${SHOW}\r"
      wrn "${name} — 手動で確認してみて: ${CYN}http://localhost:${port}${R}"
      return 0
    fi

    sleep 0.15
  done
}

wait_for_app "$PORT_MG"  "MoneyGlass"    "🏦" "$MG_COLOR"
wait_for_app "$PORT_PD"  "PolicyDiff"    "📋" "$PD_COLOR"
wait_for_app "$PORT_PS"  "ParliScope"    "🏛️ " "$PS_COLOR"
[ -d "apps/seatmap-web" ]      && wait_for_app "$PORT_SM" "SeatMap"       "💺" "$SM_COLOR"
[ -d "apps/culturescope-web" ] && wait_for_app "$PORT_CS" "CultureScope"  "🎨" "$CS_COLOR"
[ -d "apps/socialguard-web" ]  && wait_for_app "$PORT_SG" "SocialGuard"   "🛡️ " "$SG_COLOR"
step_pct

# =============================================================================
#  ✧  COMPLETE — 祝！完成！ ✧
# =============================================================================
ELAPSED=$((SECONDS - TOTAL_START))
MINS=$((ELAPSED / 60))
SECS=$((ELAPSED % 60))

printf "\a"  # bell

echo ""
echo ""
rainbow_bar_block
rainbow_bar_block
echo ""

echo -ne "  "; rainbow_wave "██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗" 0; echo ""
echo -ne "  "; rainbow_wave "██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝" 3; echo ""
echo -ne "  "; rainbow_wave "██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝ " 6; echo ""
echo -ne "  "; rainbow_wave "██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝  " 9; echo ""
echo -ne "  "; rainbow_wave "██║  ██║███████╗██║  ██║██████╔╝   ██║   " 12; echo ""
echo -ne "  "; rainbow_wave "╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝   " 15; echo ""

echo ""
rainbow_bar_block
rainbow_bar_block
echo ""
echo ""

# ── App count ──
APP_COUNT=6
[ -d "apps/moneyglass-admin" ] && APP_COUNT=$((APP_COUNT + 1))
[ -d "apps/parliscope-admin" ] && APP_COUNT=$((APP_COUNT + 1))

# ── Decorative box top ──
echo -e "  ${DGRAY}╔══════════════════════════════════════════════════════════════════════╗${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}  $(rainbow '🌟★🔥 全 '"$APP_COUNT"' アプリ起動完了 🔥★🌟')  ${WHT}${B}${MINS}分${SECS}秒${R}${GRAY}で構築${R}       ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"
echo -e "  ${DGRAY}╠══════════════════════════════════════════════════════════════════════╣${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"

# ── Public apps ──
echo -e "  ${DGRAY}║${R}  ${MG_COLOR}${B}💰🏦 MoneyGlass${R}   ${DGRAY}─────${R}  ${CYN}${UL}http://localhost:${PORT_MG}${R}              ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${PEACH}💎 政治資金を、ガラスのように透明に ✨${R}                   ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${GRAY}🔢 13政党 · 8年分 · 政治資金収支報告書${R}                   ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"

echo -e "  ${DGRAY}║${R}  ${PD_COLOR}${B}📜📋 PolicyDiff${R}   ${DGRAY}─────${R}  ${CYN}${UL}http://localhost:${PORT_PD}${R}              ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${MINT}🔀 全政党の政策を、差分で比較する ✨${R}                     ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${GRAY}🔢 15政党 · 10カテゴリ · マニフェスト比較${R}                ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"

echo -e "  ${DGRAY}║${R}  ${PS_COLOR}${B}🏛️✨ ParliScope${R}   ${DGRAY}─────${R}  ${CYN}${UL}http://localhost:${PORT_PS}${R}              ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${LAVD}🔭 議会を、すべての人とエージェントに開く ✨${R}             ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${GRAY}🔢 90法案 · 713議員 · 21会期${R}                            ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"

echo -e "  ${DGRAY}║${R}  ${SM_COLOR}${B}💺🗺️ SeatMap${R}       ${DGRAY}─────${R}  ${CYN}${UL}http://localhost:${PORT_SM}${R}              ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${ORNG}🎯 議会の勢力図を、ひと目で把握する ✨${R}                   ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${GRAY}🔢 衆参両院 · 9選挙 · スプリング物理${R}                    ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"

echo -e "  ${DGRAY}║${R}  ${CS_COLOR}${B}🎨🎭 CultureScope${R} ${DGRAY}─────${R}  ${CYN}${UL}http://localhost:${PORT_CS}${R}              ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${GOLD}🖼️ 文化を、政治の言語で読み解く ✨${R}                       ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${GRAY}🔢 96予算 · 20プログラム · 12分野 · 13政党スタンス${R}       ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"

echo -e "  ${DGRAY}║${R}  ${SG_COLOR}${B}🛡️🏥 SocialGuard${R}  ${DGRAY}─────${R}  ${CYN}${UL}http://localhost:${PORT_SG}${R}              ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${MINT}🤝 社会保障の全体像を、ひと目で ✨${R}                       ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${GRAY}🔢 64予算 · 15制度 · 47都道府県 · 13政党スタンス${R}         ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"
echo -e "  ${DGRAY}╠══════════════════════════════════════════════════════════════════════╣${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}  ${GRAY}管理画面${R}  ${MGA_COLOR}localhost:${PORT_MGA}${R} ${GRAY}(MoneyGlass)${R}  ${PSA_COLOR}localhost:${PORT_PSA}${R} ${GRAY}(ParliScope)${R} ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"
echo -e "  ${DGRAY}╠══════════════════════════════════════════════════════════════════════╣${R}"
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"
if [ "$ENTIRE_OK" = true ]; then
echo -e "  ${DGRAY}║${R}  ${LAVD}${B}🧠 Entire${R}  ${GRN}有効${R} ${GRAY}— エージェントの思考がGitで共有されるよ！${R}         ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${GRAY}📖 entire explain${R} ${DGRAY}—${R} ${GRAY}コミットの背景を参照${R}                     ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${GRAY}📊 entire status${R}  ${DGRAY}—${R} ${GRAY}セッションの状態確認${R}                     ${DGRAY}║${R}"
else
echo -e "  ${DGRAY}║${R}  ${LAVD}${B}🧠 Entire${R}  ${GOLD}未設定${R} ${GRAY}— あとで導入できるよ:${R}                      ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${CYN}brew tap entireio/tap && brew install entireio/tap/entire${R}   ${DGRAY}║${R}"
echo -e "  ${DGRAY}║${R}     ${CYN}entire enable${R}                                               ${DGRAY}║${R}"
fi
echo -e "  ${DGRAY}║${R}                                                                      ${DGRAY}║${R}"
echo -e "  ${DGRAY}╚══════════════════════════════════════════════════════════════════════╝${R}"
echo ""

# ── Data summary ──
echo -e "  ${DGRAY}┌──────────────────────────────────────────────────────────────────┐${R}"
echo -e "  ${DGRAY}│${R}  ${WHT}${B}📊🗂️ 搭載データ ～これだけ入ってるよ！～${R}                         ${DGRAY}│${R}"
echo -e "  ${DGRAY}│${R}                                                                    ${DGRAY}│${R}"
echo -e "  ${DGRAY}│${R}  ${HOT}15${R}${GRAY}政党${R}  ${PURP}713${R}${GRAY}議員${R}  ${SKY}90${R}${GRAY}法案${R}  ${GOLD}9${R}${GRAY}選挙${R}  ${MINT}47${R}${GRAY}都道府県${R}  ${ORNG}29${R}${GRAY}DBモデル${R}    ${DGRAY}│${R}"
echo -e "  ${DGRAY}│${R}  ${CS_COLOR}96${R}${GRAY}文化予算${R}  ${SG_COLOR}64${R}${GRAY}社保予算${R}  ${SG_COLOR}15${R}${GRAY}社保制度${R}  ${CS_COLOR}20${R}${GRAY}文化プログラム${R}       ${DGRAY}│${R}"
echo -e "  ${DGRAY}│${R}                                                                    ${DGRAY}│${R}"
echo -e "  ${DGRAY}│${R}  ${GRAY}📚 データソース: 総務省・文化庁・厚労省・財務省・衆参両院公式${R}    ${DGRAY}│${R}"
echo -e "  ${DGRAY}└──────────────────────────────────────────────────────────────────┘${R}"
echo ""

# ── Tips ──
echo -e "  ${GOLD}💡🌐 ブラウザで開く方法 ～かんたん3ステップ～${R}"
echo -e "  ${GRAY}────────────────────────────────────────────${R}"
echo -e "  ${WHT}方法①${R} ${GRAY}URLを ${WHT}右クリック${R} ${GRAY}→「リンクを開く」を選ぶ${R}"
echo -e "  ${WHT}方法②${R} ${GRAY}URLをマウスで選択して ${WHT}コピー${R}${GRAY}（⌘+C）${R}"
echo -e "          ${GRAY}→ ブラウザのアドレスバーに ${WHT}ペースト${R}${GRAY}（⌘+V）して Enter${R}"
echo -e "  ${WHT}方法③${R} ${GRAY}⌘ キーを押しながら URL をクリック${R}"
echo ""

echo -ne "  "; rainbow "(ﾉ◕ヮ◕)ﾉ*:・ﾟ✧  全 ${APP_COUNT} アプリ起動完了！！ ﾔｯﾀｰ！！！"; echo ""
echo -e "  ${WHT}${B}⚡ ${MINS}分${SECS}秒${R}${GRAY}で全環境が整ったよ！さあ政治を見に行こう！🏃‍♂️💨${R}"
echo ""

echo -e "  ${GRAY}🛑 やめるとき${R}      ${DGRAY}→${R}  ${WHT}Ctrl+C${R}"
echo -e "  ${GRAY}🔄 もう一回やる${R}    ${DGRAY}→${R}  ${WHT}bash setup.sh${R}"
echo -e "  ${GRAY}🗑️  データも消す${R}    ${DGRAY}→${R}  ${WHT}podman compose down -v${R}"
echo ""
rainbow_bar
echo ""
echo -e "  ${PEACH}🎉🎊🥳 おめでとう！日本の政治データが手のひらに！🇯🇵✨${R}"
echo -e "  ${GRAY}👆 上の URL をブラウザで開いて、6つのアプリで政治を探索しよう 🌏🔍${R}"
echo ""

# Keep running — wait for any app to exit, then wait for all
wait "${APP_PIDS[@]}" 2>/dev/null || true
