#!/bin/bash # シバン: Bash で実行することを指定
set -Eeuo pipefail # エラー即時終了・未定義変数エラー・パイプ失敗検出
IFS=$'\n\t' # IFS を安全な設定に（スペースは区切らない）
content=(herry pear banana grape peah apple) # 出題する単語の配列（各要素を分離）
# テストやカスタム出題用に CONTENT 環境変数で上書き可能（スペース区切り）
if [[ -n ${CONTENT-} ]]; then # CONTENT が設定されていれば
  IFS=' ' read -r -a content <<< "$CONTENT" # スペースで分割して配列化
fi

# 単語リスト外部化: WORDS_FILE（未指定なら assets/words.txt）から1行1語で読み込み
if [[ -z ${CONTENT-} ]]; then # CONTENT 指定がない場合のみファイル入力を有効化
  WORDS_PATH=${WORDS_FILE-assets/words.txt}
  if [[ -f "$WORDS_PATH" ]]; then
    # 空行とコメント(#～)を除去し、CRLF を正規化
    mapfile -t content < <(sed -e 's/\r$//' -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' "$WORDS_PATH")
  fi
fi
readonly ESC=$'\033' # ANSI エスケープシーケンスの開始コード（色付け用）
readonly SHOW_CURSOR="${ESC}[?25h" # カーソル表示
readonly HIDE_CURSOR="${ESC}[?25l" # カーソル非表示
# EXIT 時は色とカーソルのみ復帰（画面はクリアしない）。INT/TERM は色/カーソル復帰後に画面クリア。
trap 'printf "\033[m\033[?25h\n"' EXIT
trap 'printf "\033[m\033[?25h\n"; clear' INT TERM

typingGame(){ # 1単語分のタイピングゲームを実行する関数
  local element typed n a typed_element expected_msg # 関数内変数をローカル化
  element="$1" # 残りの未入力部分（先頭から削っていく）
  typed="$element" # 元の完全な単語（入力済み部分計算用）
  n=0 # 正しく入力できた文字数のカウンタ
  clear # 画面をクリア
  # 初期表示（3行確保: 入力行 / メッセージ / ステータス）
  typed_element=""
  expected_msg=""
  printf "\r${ESC}[2K${ESC}[34m%s${ESC}[m${ESC}[33m%s${ESC}[m\n" "$typed_element" "$element"
  printf "\r${ESC}[2K\n" # メッセージ行を空で描画
  print_status # ステータス行

  while true; do # 入力が終わるまで繰り返す無限ループ
    if [[ ${#element} -eq 0 ]]; then # 残り文字数が0なら
      break # ループを抜ける（単語入力完了）
    fi
    read -r -s -n 1 a # 1文字を非表示(-s)で読み取り、変数aに格納
    if [[ "$a" == "${element:0:1}" ]]; then # 入力が先頭の期待文字と一致したら
      n=$((n + 1)) # 正打数をインクリメント
      TOTAL_CORRECT=$((TOTAL_CORRECT + 1)) # 総正打数
      KEYSTROKES=$((KEYSTROKES + 1)) # 総キータイプ数
      typed_element="${typed:0:n}" # 入力済み部分（先頭n文字）を取得
      element="${element:1}" # 残り部分を先頭1文字削除
      expected_msg="" # ミスタイプメッセージを消去
    else # ミスタイプ時のフィードバック
      printf "\a" # ビープ音
      KEYSTROKES=$((KEYSTROKES + 1)) # 総キータイプ数
      expected_msg="期待: ${element:0:1}" # 期待文字を記録
    fi
    # カーソルを3行上に戻して3行を部分再描画（入力行/メッセージ/ステータス）
    printf "${ESC}[3F" # 3行上へ
    printf "\r${ESC}[2K${ESC}[34m%s${ESC}[m${ESC}[33m%s${ESC}[m\n" "$typed_element" "$element"
    if [[ -n "$expected_msg" ]]; then
      printf "\r${ESC}[2K${ESC}[31m%s${ESC}[m\n" "$expected_msg"
    else
      printf "\r${ESC}[2K\n"
    fi
    print_status # 進捗表示
  done # while ループ終了
} # 関数終了

# 進捗/統計のグローバル変数
TOTAL_CORRECT=0 # 総正打数
KEYSTROKES=0 # 総キータイプ数（誤入力含む）
TOTAL_TARGET=0 # 総ターゲット文字数
WORD_COUNT=${#content[@]} # 総単語数
WORDS_DONE=0 # 完了した単語数
START_SECONDS=$SECONDS # 開始時間（秒）

# 総ターゲット文字数を算出
for w in "${content[@]}"; do
  TOTAL_TARGET=$((TOTAL_TARGET + ${#w}))
done

# 進捗表示関数
print_status(){
  local elapsed=$((SECONDS - START_SECONDS))
  local acc=0
  if [[ $KEYSTROKES -gt 0 ]]; then
    acc=$((100 * TOTAL_CORRECT / KEYSTROKES))
  fi
  local wpm=0
  if [[ $elapsed -gt 0 ]]; then
    # (correct_chars/5) / (elapsed/60) = correct_chars * 12 / elapsed
    wpm=$(( TOTAL_CORRECT * 12 / elapsed ))
  fi
  printf "\r${ESC}[2K${ESC}[36m単語: %d/%d | 文字: %d/%d | 打鍵: %d | 正確性: %d%% | 経過: %ds | WPM: %d${ESC}[m\n" \
    "$WORDS_DONE" "$WORD_COUNT" "$TOTAL_CORRECT" "$TOTAL_TARGET" "$KEYSTROKES" "$acc" "$elapsed" "$wpm"
}

# 任意: シャッフル（SHUFFLE=1 のとき）
if [[ ${SHUFFLE-} == 1 ]]; then
  # shuf があれば利用
  if command -v shuf >/dev/null 2>&1; then
    mapfile -t content < <(printf '%s\n' "${content[@]}" | shuf)
  fi
fi

for value in ${content[@]}; do # 配列内の各単語に対してゲームを実行
  typingGame "$value" # 単語を引数に関数呼び出し
  WORDS_DONE=$((WORDS_DONE + 1)) # 単語完了をカウント
  clear
  print_status
done # ループ終了

# 終了サマリ
printf "${HIDE_CURSOR}" >/dev/null 2>&1 # 念のため非表示状態に（既定動作）
printf "${SHOW_CURSOR}" # 終了時にカーソルを表示
printf "${ESC}[32m完了しました！${ESC}[m\n"
print_status
