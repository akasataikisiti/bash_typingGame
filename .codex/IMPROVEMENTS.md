# 改善提案（Typing Game Bash）

## 概要
小規模な Bash スクリプトですが、入力の堅牢性・表示の安定性・拡張性・品質管理の整備で体験が大幅に向上します。以下は優先度順の提案です。

## すぐ直せるバグ/安全性
- 配列初期化の修正: 現状は1要素に全語が入っています。例:
  - 正: `content=("cherry" "pear" "banana" "grape" "peach" "apple")`
  - もしくは: `content=(cherry pear banana grape peach apple)`
- 端末復帰の確実化: 例外時でも色をリセットし画面を整える `trap` を追加。
  - `trap 'printf "\033[m\n"; clear' INT TERM EXIT`
- 安全オプション: `set -Eeuo pipefail` と `IFS=$'\n\t'` を先頭に。
- `echo -e/-n` 依存を減らし `printf` を使用（移植性/予測可能性向上）。
- 変数のクォートと `[[ ... ]]` 条件式、関数内 `local` の徹底。

## 表示/UX 改善
- ミスタイプ表示: 不一致時に赤点灯やビープ音（`printf "\a"`）。
- 進捗/スコア: 文字数/単語数、経過時間、WPM、正答率を表示。
- 難易度: 単語長や記号を含むリスト、ランダム化/シャッフル。
- 単語ソース外部化: `assets/words.txt` から読み込み可能に。

## コード整理
- 関数分割: 入力処理、描画、採点、データ読込を分離。
- 定数: `readonly ESC=$'\033'` などで明示。
- 端末制御: ANSI シーケンスを `printf` ラッパ関数に集約（`draw_typed`, `draw_remaining` など）。

## テスト/品質管理
- Lint/Format: `shellcheck` と（任意で）`shfmt` を導入。
- テスト: Bats を使用。Docker の `bats/bats:latest` で実行（`scripts/test-docker.sh`）。
  - 擬似 TTY が必要な検証は util-linux の `script` を併用。
- CI: GitHub Actions で `shellcheck` と Docker 上の Bats を実行。
- Makefile: `run`, `lint`, `fmt`, `test-docker`, `ci` ターゲットを用意。

## 参考スニペット
```bash
set -Eeuo pipefail
IFS=$'\n\t'
readonly ESC=$'\033'
trap 'printf "${ESC}[m\n"; clear' INT TERM EXIT

content=("cherry" "pear" "banana" "grape" "peach" "apple")

draw() {
  local typed="$1" remaining="$2"
  printf "${ESC}[34m%s${ESC}[m${ESC}[33m%s${ESC}[m\n" "$typed" "$remaining"
}
```
