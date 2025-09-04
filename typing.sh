#!/bin/bash
readonly ESC=$'\033'               # ANSI エスケープシーケンスの開始コード（色付け用）
readonly SHOW_CURSOR="${ESC}[?25h" # カーソル表示
readonly HIDE_CURSOR="${ESC}[?25l" # カーソル非表示
readonly RESET="${ESC}[m"
readonly BLUE="${ESC}[34m"
readonly YELLOW="${ESC}[33m"
readonly RED="${ESC}[31m"
readonly CYAN="${ESC}[36m"
readonly GREEN="${ESC}[32m"
readonly CLEARLINE="\r${ESC}[2K"
readonly UP3="${ESC}[3F"

# 非TTY環境（CI/Batsなど）でも安全に動作させるUIユーティリティ
is_tty() { [[ -t 1 ]]; }
ui_clear() { if is_tty; then clear || true; fi; }
ui_hide_cursor() { if is_tty; then printf "%s" "${HIDE_CURSOR}" || true; fi; }
ui_show_cursor() { if is_tty; then printf "%s" "${SHOW_CURSOR}" || true; fi; }
read_char() {
  # 使用: read_char varname
  local __var=$1 c
  if [[ -t 0 ]]; then
    read -r -s -n 1 c || return $?
  else
    read -r -n 1 c || return $?
  fi
  printf -v "$__var" '%s' "$c"
}

typing_play_word() {                                 # 1単語分のタイピングを処理する関数（内部用）
  local element typed n a typed_element expected_msg # 関数内変数をローカル化
  element="$1"                                       # 残りの未入力部分（先頭から削っていく）
  typed="$element"                                   # 元の完全な単語（入力済み部分計算用）
  n=0                                                # 正しく入力できた文字数のカウンタ
  ui_clear                                           # 画面をクリア（非TTY時は無視）
  # 初期表示（3行確保: 入力行 / メッセージ / ステータス）
  typed_element=""
  expected_msg=""
  printf "%s%s%s%s%s\n" "${CLEARLINE}${BLUE}" "$typed_element" "${RESET}${YELLOW}" "$element" "$RESET"
  printf "%s\n" "$CLEARLINE" # メッセージ行を空で描画
  print_status               # ステータス行

  while true; do                                    # 入力が終わるまで繰り返す無限ループ
    if [[ ${ABORT:-0} -eq 1 ]]; then return 130; fi # 中断フラグで即終了
    if [[ ${#element} -eq 0 ]]; then                # 残り文字数が0なら
      break                                         # ループを抜ける（単語入力完了）
    fi
    read_char a                             # 1文字を読み取り、変数aに格納（非TTY対応）
    if [[ "$a" == "${element:0:1}" ]]; then # 入力が先頭の期待文字と一致したら
      n=$((n + 1))                          # 正打数をインクリメント
      TOTAL_CORRECT=$((TOTAL_CORRECT + 1))  # 総正打数
      KEYSTROKES=$((KEYSTROKES + 1))        # 総キータイプ数
      typed_element="${typed:0:n}"          # 入力済み部分（先頭n文字）を取得
      element="${element:1}"                # 残り部分を先頭1文字削除
      expected_msg=""                       # ミスタイプメッセージを消去
    else                                    # ミスタイプ時のフィードバック
      printf "\a"                           # ビープ音
      KEYSTROKES=$((KEYSTROKES + 1))        # 総キータイプ数
      expected_msg="期待: ${element:0:1}"     # 期待文字を記録
    fi
    # カーソルを3行上に戻して3行を部分再描画（入力行/メッセージ/ステータス）
    printf "%s" "$UP3" # 3行上へ（非TTYでも無害）
    printf "%s%s%s%s%s\n" "${CLEARLINE}${BLUE}" "$typed_element" "${RESET}${YELLOW}" "$element" "$RESET"
    if [[ -n "$expected_msg" ]]; then
      printf "%s%s%s\n" "$CLEARLINE" "${RED}${expected_msg}" "$RESET"
    else
      printf "%s\n" "$CLEARLINE"
    fi
    print_status # 進捗表示
  done           # while ループ終了
}                # 関数終了

# 進捗表示関数
print_status() {
  local elapsed=$((SECONDS - START_SECONDS))
  local acc=0
  if [[ $KEYSTROKES -gt 0 ]]; then
    acc=$((100 * TOTAL_CORRECT / KEYSTROKES))
  fi
  local wpm=0
  if [[ $elapsed -gt 0 ]]; then
    # (correct_chars/5) / (elapsed/60) = correct_chars * 12 / elapsed
    wpm=$((TOTAL_CORRECT * 12 / elapsed))
  fi
  printf "%s%s単語: %d/%d | 文字: %d/%d | 打鍵: %d | 正確性: %d%% | 経過: %ds | WPM: %d%s\n" \
    "$CLEARLINE" "$CYAN" \
    "$WORDS_DONE" "$WORD_COUNT" "$TOTAL_CORRECT" "$TOTAL_TARGET" "$KEYSTROKES" "$acc" "$elapsed" "$wpm" \
    "$RESET"
}

typingGame() { # ゲーム全体を実行する関数（この関数を呼び出して実行）
  # 使い方: typingGame [-f WORDS_FILE] [-c NUM] [-r]
  #   -f: 読み込む単語ファイル（1行1語）。CONTENT より優先。
  #   -c: 出題数（数値）。指定がなければ全件。
  #   -r: 出題順をシャッフル。
  # 以前の IFS とシェルオプションを退避（source 時に親シェルへ影響させない）
  local __prev_ifs="$IFS"
  # 現在の set -o 状態を復元可能な形式で保存
  local __old_set_opts
  __old_set_opts="$(set +o)"

  # 引数パース
  local opt file_override="" questions_limit="" cli_shuffle=0
  local OPTIND=1
  while getopts ":f:c:r" opt; do
    case "$opt" in
      f) file_override="$OPTARG" ;;
      c) questions_limit="$OPTARG" ;;
      r) cli_shuffle=1 ;;
      :)
        echo "オプション -$OPTARG には引数が必要です" >&2
        return 2
        ;;
      \?)
        echo "不正なオプション: -$OPTARG" >&2
        return 2
        ;;
    esac
  done
  shift $((OPTIND - 1))

  # 安全設定（関数終了時に元へ戻す）
  set -Eeuo pipefail
  IFS=$'\n\t'

  # 退出時の後始末: 色/カーソル復帰（画面はクリアしない）
  trap 'printf "%s\n" "${RESET}${SHOW_CURSOR}"' EXIT
  # Ctrl+C で中断
  ABORT=0
  on_signal() { ABORT=1; }
  trap on_signal INT TERM

  # 出題の準備（優先度: -f > CONTENT > WORDS_FILE/assets/words.txt > デフォルト配列）
  local -a content=(herry pear banana grape peah apple)
  if [[ -n "$file_override" ]]; then
    if [[ -f "$file_override" ]]; then
      mapfile -t content < <(sed -e 's/\r$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$file_override")
    else
      echo "指定ファイルがありません: $file_override" >&2
      return 2
    fi
  elif [[ -n ${CONTENT-} ]]; then
    IFS=' ' read -r -a content <<<"$CONTENT"
  else
    local WORDS_PATH="${WORDS_FILE-assets/words.txt}"
    if [[ -f "$WORDS_PATH" ]]; then
      mapfile -t content < <(sed -e 's/\r$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$WORDS_PATH")
    fi
  fi

  # 統計用変数（関数内での動的スコープ。下位関数から参照/更新される）
  TOTAL_CORRECT=0
  KEYSTROKES=0
  TOTAL_TARGET=0
  WORD_COUNT=${#content[@]}
  WORDS_DONE=0
  START_SECONDS=$SECONDS
  for w in "${content[@]}"; do TOTAL_TARGET=$((TOTAL_TARGET + ${#w})); done

  # 任意: シャッフル（-r または SHUFFLE=1）
  if { [[ $cli_shuffle -eq 1 ]] || [[ ${SHUFFLE-} == 1 ]]; } &&
    command -v shuf >/dev/null 2>&1; then
    mapfile -t content < <(printf '%s\n' "${content[@]}" | shuf)
  fi

  # 任意: 出題数を制限（-c NUM）
  if [[ -n "$questions_limit" ]]; then
    if [[ "$questions_limit" =~ ^[0-9]+$ ]] && [[ "$questions_limit" -gt 0 ]]; then
      if ((${#content[@]} > questions_limit)); then
        content=("${content[@]:0:questions_limit}")
      fi
    else
      echo "-c は正の整数を指定してください: $questions_limit" >&2
      return 2
    fi
  fi

  ui_hide_cursor

  # メインループ
  local value
  for value in "${content[@]}"; do
    typing_play_word "$value" || {
      # 中断時は以降をスキップ
      if [[ ${ABORT:-0} -eq 1 ]]; then break; fi
    }
    WORDS_DONE=$((WORDS_DONE + 1))
    ui_clear
    print_status
  done

  # 終了サマリ
  ui_show_cursor
  if [[ ${ABORT:-0} -eq 1 ]]; then
    printf "%s中断しました（Ctrl+C）%s\n" "$YELLOW" "$RESET"
  else
    printf "%s完了しました！%s\n" "$GREEN" "$RESET"
  fi
  print_status

  # トラップ/シェル状態の復元
  trap - EXIT INT TERM
  IFS="$__prev_ifs"
  # set オプションを元に戻す
  eval "$__old_set_opts"
} # typingGame 終了

# スクリプトとして直接実行された場合のみゲームを起動（source された場合は関数定義のみ）
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  typingGame "$@"
fi
