#!/bin/bash
# Bash 実行シェルを指定
readonly ESC=$'\033'               # ANSI エスケープシーケンスの開始コード（色付け用）
readonly SHOW_CURSOR="${ESC}[?25h" # カーソル表示
readonly HIDE_CURSOR="${ESC}[?25l" # カーソル非表示
readonly RESET="${ESC}[m"          # 色/装飾をリセット
readonly BLUE="${ESC}[34m"         # 青色
readonly YELLOW="${ESC}[33m"       # 黄色
readonly RED="${ESC}[31m"          # 赤色
readonly CYAN="${ESC}[36m"         # シアン
readonly GREEN="${ESC}[32m"        # 緑色
readonly CLEARLINE="\r${ESC}[2K"   # 行をクリアして先頭へ戻る
readonly UP3="${ESC}[3F"           # カーソルを3行上へ移動

# 非TTY環境（CI/Batsなど）でも安全に動作させるUIユーティリティ
is_tty() { [[ -t 1 ]]; }                                                       # 標準出力がTTYか判定
ui_clear() { if is_tty; then clear || true; fi; }                              # 画面クリア（TTY時のみ）
ui_hide_cursor() { if is_tty; then printf "%s" "${HIDE_CURSOR}" || true; fi; } # カーソル非表示
ui_show_cursor() { if is_tty; then printf "%s" "${SHOW_CURSOR}" || true; fi; } # カーソル表示
read_char() {                                                                  # 1文字読み取り（変数名を引数で受け取る）
  # 使用: read_char varname
  local __var=$1 c                 # 代入先変数名と読み取り用の一時変数
  if [[ -t 0 ]]; then              # 標準入力がTTYかどうか
    read -r -s -n 1 c || return $? # エコーなしで1文字読む（失敗時は同じ終了コードで返す）
  else
    read -r -n 1 c || return $? # パイプ/非TTY時はエコーありで1文字読む
  fi
  printf -v "$__var" '%s' "$c" # 読み取った文字を参照名の変数へ代入
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
  printf "%s%s%s%s%s\n" "${CLEARLINE}${BLUE}" "$typed_element" "${RESET}${YELLOW}" "$element" "$RESET" # 入力済み(青)と残り(黄)を表示
  printf "%s\n" "$CLEARLINE"                                                                           # メッセージ行を空で描画
  print_status                                                                                         # ステータス行

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
    printf "%s" "$UP3"                                                                                   # 3行上へ（非TTYでも無害）
    printf "%s%s%s%s%s\n" "${CLEARLINE}${BLUE}" "$typed_element" "${RESET}${YELLOW}" "$element" "$RESET" # 再描画: 入力行
    if [[ -n "$expected_msg" ]]; then
      printf "%s%s%s\n" "$CLEARLINE" "${RED}${expected_msg}" "$RESET"
    else
      printf "%s\n" "$CLEARLINE"
    fi
    print_status # 進捗表示
  done           # while ループ終了
}                # 関数終了

# 進捗表示関数
print_status() {                              # 進捗の統計を1行で表示
  local elapsed=$((SECONDS - START_SECONDS))  # 経過秒数
  local acc=0                                 # 正確性(%)
  if [[ $KEYSTROKES -gt 0 ]]; then            # 1打以上のときのみ計算
    acc=$((100 * TOTAL_CORRECT / KEYSTROKES)) # 正打/総打鍵から算出
  fi
  local wpm=0                   # 1分あたり語数(WPM)
  if [[ $elapsed -gt 0 ]]; then # 0除算回避
    # (correct_chars/5) / (elapsed/60) = correct_chars * 12 / elapsed
    wpm=$((TOTAL_CORRECT * 12 / elapsed)) # 1語=5文字として計算
  fi
  printf "%s%s単語: %d/%d | 文字: %d/%d | 打鍵: %d | 正確性: %d%% | 経過: %ds | WPM: %d%s\n" \
    "$CLEARLINE" "$CYAN" \
    "$WORDS_DONE" "$WORD_COUNT" "$TOTAL_CORRECT" "$TOTAL_TARGET" "$KEYSTROKES" "$acc" "$elapsed" "$wpm" \
    "$RESET" # ステータス行を色付きで表示
}

typingGame() { # ゲーム全体を実行する関数（この関数を呼び出して実行）
  # 使い方: typingGame [-f WORDS_FILE] [-c NUM] [-r]
  #   -f: 読み込む単語ファイル（1行1語）。CONTENT より優先。
  #   -c: 出題数（数値）。指定がなければ全件。
  #   -r: 出題順をシャッフル。
  # 以前の IFS とシェルオプションを退避（source 時に親シェルへ影響させない）
  local __prev_ifs="$IFS" # 元のIFSを退避
  # 現在の set -o 状態を復元可能な形式で保存
  local __old_set_opts
  __old_set_opts="$(set +o)" # 現在の set オプション状態を保存

  # 引数パース
  local opt file_override="" questions_limit="" cli_shuffle=0 # 引数格納用の変数
  local OPTIND=1                                              # getopts の初期化
  while getopts ":f:c:r" opt; do                              # オプション解析
    case "$opt" in
      f) file_override="$OPTARG" ;;   # -f: ファイル指定
      c) questions_limit="$OPTARG" ;; # -c: 問題数
      r) cli_shuffle=1 ;;             # -r: シャッフル有効
      :)
        echo "オプション -$OPTARG には引数が必要です" >&2 # 必須引数なし
        return 2
        ;;
      \?)
        echo "不正なオプション: -$OPTARG" >&2 # 未知のオプション
        return 2
        ;;
    esac
  done
  shift $((OPTIND - 1)) # 位置引数から処理済みオプションを除去

  # 安全設定（関数終了時に元へ戻す）
  set -Eeuo pipefail # 厳格モード
  IFS=$'\n\t'        # IFS を改行/タブに限定

  # 退出時の後始末: 色/カーソル復帰（画面はクリアしない）
  trap 'printf "%s\n" "${RESET}${SHOW_CURSOR}"' EXIT # 終了時に色とカーソルを復元
  # Ctrl+C で中断
  ABORT=0                  # 中断フラグ初期化
  on_signal() { ABORT=1; } # シグナル受信時に中断フラグを立てる
  trap on_signal INT TERM  # Ctrl+C などを捕捉

  # 出題の準備（優先度: -f > CONTENT > WORDS_FILE/assets/words.txt > デフォルト配列）
  local -a content=(herry pear banana grape peah apple) # デフォルト問題（例）
  if [[ -n "$file_override" ]]; then
    if [[ -f "$file_override" ]]; then                                                                        # 存在確認
      mapfile -t content < <(sed -e 's/\r$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$file_override") # CR削除/コメント・空行除去
    else
      echo "指定ファイルがありません: $file_override" >&2 # ファイルエラー
      return 2
    fi
  elif [[ -n ${CONTENT-} ]]; then            # 環境変数 CONTENT があれば優先
    IFS=' ' read -r -a content <<<"$CONTENT" # 空白区切りで配列化
  else
    local WORDS_PATH="${WORDS_FILE-assets/words.txt}" # デフォルトの単語ファイル
    if [[ -f "$WORDS_PATH" ]]; then
      mapfile -t content < <(sed -e 's/\r$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$WORDS_PATH") # 正規化して読み込み
    fi
  fi

  # 統計用変数（関数内での動的スコープ。下位関数から参照/更新される）
  TOTAL_CORRECT=0                                                           # 総正打数
  KEYSTROKES=0                                                              # 総打鍵数
  TOTAL_TARGET=0                                                            # 目標文字数（全単語の合計）
  WORD_COUNT=${#content[@]}                                                 # 出題単語数
  WORDS_DONE=0                                                              # 完了単語数
  START_SECONDS=$SECONDS                                                    # 開始時刻
  for w in "${content[@]}"; do TOTAL_TARGET=$((TOTAL_TARGET + ${#w})); done # 合計目標文字数を計算

  # 任意: シャッフル（-r または SHUFFLE=1）
  if { [[ $cli_shuffle -eq 1 ]] || [[ ${SHUFFLE-} == 1 ]]; } &&  # 指定があれば
    command -v shuf >/dev/null 2>&1; then                        # shuf が利用可能なら
    mapfile -t content < <(printf '%s\n' "${content[@]}" | shuf) # 配列をシャッフル
  fi

  # 任意: 出題数を制限（-c NUM）
  if [[ -n "$questions_limit" ]]; then                                              # 出題数の上限が指定されている場合
    if [[ "$questions_limit" =~ ^[0-9]+$ ]] && [[ "$questions_limit" -gt 0 ]]; then # 正の整数チェック
      if ((${#content[@]} > questions_limit)); then
        content=("${content[@]:0:questions_limit}") # 先頭から指定数に切り詰め
      fi
    else
      echo "-c は正の整数を指定してください: $questions_limit" >&2 # バリデーションエラー
      return 2
    fi
  fi

  ui_hide_cursor # カーソルを隠す

  # メインループ
  local value                      # ループ用一時変数
  for value in "${content[@]}"; do # 各単語に対して
    typing_play_word "$value" || { # 単語のプレイ。失敗時は中断フラグを確認
      # 中断時は以降をスキップ
      if [[ ${ABORT:-0} -eq 1 ]]; then break; fi
    }
    WORDS_DONE=$((WORDS_DONE + 1)) # 完了カウントを更新
    ui_clear                       # 画面をクリア
    print_status                   # 進捗を表示
  done

  # 終了サマリ
  ui_show_cursor # カーソルを表示に戻す
  if [[ ${ABORT:-0} -eq 1 ]]; then
    printf "%s中断しました（Ctrl+C）%s\n" "$YELLOW" "$RESET" # 中断メッセージ
  else
    printf "%s完了しました！%s\n" "$GREEN" "$RESET" # 完了メッセージ
  fi
  print_status # 最終ステータス表示

  # トラップ/シェル状態の復元
  trap - EXIT INT TERM # トラップ解除
  IFS="$__prev_ifs"    # IFS 復元
  # set オプションを元に戻す
  eval "$__old_set_opts" # set 状態の復元
}                        # typingGame 終了

# スクリプトとして直接実行された場合のみゲームを起動（source された場合は関数定義のみ）
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then # 直接実行されたかを判定
  typingGame "$@"                        # 直接実行時のみゲーム開始
fi                                       # ここでスクリプト終了
