#!/bin/bash # シバン: Bash で実行することを指定
set -Eeuo pipefail # エラー即時終了・未定義変数エラー・パイプ失敗検出
IFS=$'\n\t' # IFS を安全な設定に（スペースは区切らない）
content=(herry pear banana grape peah apple) # 出題する単語の配列（各要素を分離）
# テストやカスタム出題用に CONTENT 環境変数で上書き可能（スペース区切り）
if [[ -n ${CONTENT-} ]]; then # CONTENT が設定されていれば
  IFS=' ' read -r -a content <<< "$CONTENT" # スペースで分割して配列化
fi
readonly ESC=$'\033' # ANSI エスケープシーケンスの開始コード（色付け用）
trap 'printf "${ESC}[m\n"; clear' INT TERM EXIT # 異常終了時も色をリセットして画面を整える

typingGame(){ # 1単語分のタイピングゲームを実行する関数
  local element typed n a typed_element # 関数内変数をローカル化
  element="$1" # 残りの未入力部分（先頭から削っていく）
  typed="$element" # 元の完全な単語（入力済み部分計算用）
  n=0 # 正しく入力できた文字数のカウンタ
  clear # 画面をクリア
  printf "${ESC}[33m%s${ESC}[m\n" "$element" # 残りの単語を黄色で表示

  while true; do # 入力が終わるまで繰り返す無限ループ
    if [[ ${#element} -eq 0 ]]; then # 残り文字数が0なら
      break # ループを抜ける（単語入力完了）
    fi
    read -r -s -n 1 a # 1文字を非表示(-s)で読み取り、変数aに格納
    if [[ "$a" == "${element:0:1}" ]]; then # 入力が先頭の期待文字と一致したら
      clear # 画面をクリア
      n=$((n + 1)) # 正打数をインクリメント
      TOTAL_CORRECT=$((TOTAL_CORRECT + 1)) # 総正打数
      KEYSTROKES=$((KEYSTROKES + 1)) # 総キータイプ数
      typed_element="${typed:0:n}" # 入力済み部分（先頭n文字）を取得
      element="${element:1}" # 残り部分を先頭1文字削除
      printf "${ESC}[34m%s${ESC}[m" "$typed_element" # 入力済み部分を青で表示（改行なし）
      printf "${ESC}[33m%s${ESC}[m\n" "$element" # 残り部分を黄色で表示し改行、色リセット
      print_status # 進捗表示
    else # ミスタイプ時のフィードバック
      printf "\a" # ビープ音
      KEYSTROKES=$((KEYSTROKES + 1)) # 総キータイプ数
      clear # 画面をリフレッシュ
      typed_element="${typed:0:n}" # 現在の入力済み部分を再描画
      printf "${ESC}[34m%s${ESC}[m" "$typed_element"
      printf "${ESC}[33m%s${ESC}[m\n" "$element"
      printf "${ESC}[31m期待: %s${ESC}[m\n" "${element:0:1}" # 期待文字を赤で表示
      print_status # 進捗表示
    fi
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
  printf "${ESC}[36m単語: %d/%d | 文字: %d/%d | 打鍵: %d | 正確性: %d%% | 経過: %ds | WPM: %d${ESC}[m\n" \
    "$WORDS_DONE" "$WORD_COUNT" "$TOTAL_CORRECT" "$TOTAL_TARGET" "$KEYSTROKES" "$acc" "$elapsed" "$wpm"
}

for value in ${content[@]}; do # 配列内の各単語に対してゲームを実行
  typingGame "$value" # 単語を引数に関数呼び出し
  WORDS_DONE=$((WORDS_DONE + 1)) # 単語完了をカウント
  clear
  print_status
done # ループ終了

# 終了サマリ
printf "${ESC}[32m完了しました！${ESC}[m\n"
print_status
