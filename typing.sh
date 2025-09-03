#!/bin/bash # シバン: Bash で実行することを指定
content=("herry pear banana grape peah apple") # 出題する単語（スペース区切り）の配列
ESC=$(printf '\033') # ANSI エスケープシーケンスの開始コード（色付け用）

typingGame(){ # 1単語分のタイピングゲームを実行する関数
  element=$1 # 残りの未入力部分（先頭から削っていく）
  typed=$element # 元の完全な単語（入力済み部分計算用）
  n=0 # 正しく入力できた文字数のカウンタ
  clear # 画面をクリア
  echo "${ESC}[33m$element${ESC}[m" # 残りの単語を黄色で表示

  while true; do # 入力が終わるまで繰り返す無限ループ
    if [ ${#element} -eq 0 ]; then # 残り文字数が0なら
      break # ループを抜ける（単語入力完了）
    fi
    read -s -n 1 a # 1文字を非表示(-s)で読み取り、変数aに格納
    if [ $a == ${element:0:1} ]; then # 入力が先頭の期待文字と一致したら
      clear # 画面をクリア
      n=$((n + 1)) # 正打数をインクリメント
      typed_element=${typed:0:n} # 入力済み部分（先頭n文字）を取得
      element=${element:1} # 残り部分を先頭1文字削除
      echo -n "${ESC}[34m$typed_element${ESC}[m" # 入力済み部分を青で表示（改行なし）
      echo -n -e "${ESC}[33m$element\n${ESC}[m" # 残り部分を黄色で表示し改行、色リセット
    fi
  done # while ループ終了
} # 関数終了

for value in ${content[@]}; do # 配列内の各単語に対してゲームを実行
  typingGame $value # 単語を引数に関数呼び出し
done # ループ終了
