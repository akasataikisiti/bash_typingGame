#+ ブランチ保護ルール設定手順（GitHub）

以下は `main` ブランチを例に、CI 成功を必須にする保護設定の手順です。

## 前提
- `.github/workflows/ci.yml` が存在し、ワークフロー名は `CI`。
- リポジトリに管理者権限があること。

## 設定手順
1. GitHub のリポジトリページを開く。
2. `Settings` → `Branches` → `Branch protection rules` → `Add rule` をクリック。
3. `Branch name pattern` に `main` を入力。
4. チェックする項目:
   - Require a pull request before merging（必要なら Approvals 数を設定）
   - Require status checks to pass before merging
     - `Require branches to be up to date before merging`（任意）
     - Status checks: `CI` を選択
   - Require signed commits（任意）
   - Require linear history（任意）
   - Do not allow bypassing the above settings（任意）
   - Do not allow force pushes / Do not allow deletions（推奨）
5. `Create` または `Save changes` をクリックして保存。

## 運用ヒント
- Renovate など Bot を使う場合は `Allow specified actors to bypass required pull requests` を最小限で付与。
- 大規模変更で一時的に `Require branches to be up to date` を外す選択肢もありますが、原則は有効を推奨。
- ワークフロー名を変更した場合は、保護設定の対象ステータスチェックも更新してください。
