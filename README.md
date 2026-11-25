# typle-r-rails-daisyui

typle-r（Next.js）を Ruby on Rails 8.1 で作り直した [typle-r-rails](https://github.com/Sparklingstadt/typle-r-rails) の、UI を shadcn/ui から [daisyUI](https://daisyui.com/) に置き換えた版です。コマンド・構文・外国語の単語を、打って覚えます。機能は typle-r-rails と同じで、見た目だけが daisyUI のものになっています。

## 動かす

```bash
bundle install          # gem は vendor/bundle に入ります
bin/rails db:setup      # DB を作り、デモのアカウント（ID demo、公式パックを1つフォロー）を入れる
bin/rails server -p 3010
```

デモのアカウントにはパスワードがありません（typle-r と同じく、ログインは Sparklingstadt ID と GitHub だけです）。開発中は `LOCAL_DEVELOPMENT_LOGIN=1 bin/rails server -p 3010` で起動すると、このマシンからのアクセスに限り、ログイン画面に「開発用のデモアカウントでログイン」が出ます（typle-r の開発用のローカルログイン `authorizeLocal` に当たるもの。development 環境だけで、本番やテストでは出ません）。

テスト: `bin/rails test`（サンドボックスなどで並列実行のソケットが使えないときは `PARALLEL_WORKERS=1 bin/rails test`）

## できること

| 画面 | パス | 内容 |
|---|---|---|
| はじめに | `/` | 紹介と、その場で1語打てる欄 |
| ホーム | `/home` | 続きから・今週のまとめ・苦手な単語・次に練習するリスト |
| 練習 | `/play` | タイピング・思い出して打つ（`?mode=recall`）・Handwriting（`?mode=writing`）。`?review=weak` で苦手な単語だけ（記録しない） |
| 練習記録・ベスト記録 | `/records`・`/rankings` | ベストは今の語数の記録を、正確率 → 時間の順に、モードごとに比べる（typle-r と同じ） |
| 単語パック | `/packs` | パック → リスト → 単語の作成・編集・削除・複製・ほかのパックへの移動、パックファイル（`.typle-pack.json`）とリストの CSV の取り込み・書き出し、手書きの言語の印。保存後は typle-r と同じく一覧に戻り、そのパック（`?pack=`）やリスト（`?list=`）を開いて強調し、画面下に通知を出す |
| 単語一覧 | `/words` | すべての単語を検索 |
| 公式パック | `/catalog` | typle-r の 269 リスト（71 パック）。カタログ ID は typle-r と同じ。関心に合うものを先に並べる |
| ログイン | `/signin` | Sparklingstadt ID（`/auth/sid`）と GitHub（`/auth/github`）のボタン。`?returnTo=` のページに戻る。失敗すると `?error=1` で戻り、1つのメッセージを出す |
| 一般 | `/settings/general` | 表示言語（日本語・English・简体中文・繁體中文・Русский・Français、Cookie に1年） |
| 入力 | `/settings` | 特殊文字の簡易入力（á→a、ш→sh、ß→ss、¿→?）、大文字・小文字を区別しない。typle-r と同じく、このブラウザーに保存（Cookie） |
| 関心 | `/interests` | 語学・プログラミングとそのタグ。合う公式パックをまとめてフォロー・解除 |
| 端末 | `/devices` | 練習した端末を記録に残す。組み込みの「デフォルト」、未選択、このブラウザーで使う端末（Cookie） |
| アカウント | `/settings/general` | すべての端末からログアウト（typle-r と同じく一般設定の中） |
| 使い方・Typleについて | `/guide`・`/about`・`/about/licenses` | ライセンス一覧（同梱の gem と onnxruntime-web・PaddleOCR、全文は `/about/licenses.txt`） |
| 共有された結果 | `/result` | X で共有した練習結果をリンクだけから表示（typle-r と同じ。SNS 用の画像は作らない） |

- **ゲスト**: ログインしなくても全部の機能が使えます。データは「このブラウザー」に結び付いたゲストのデータ（署名付き Cookie で識別）としてサーバーに保存し、アカウントとは分けます。ログインしてもコピーせず、ログアウトするとゲストのデータに戻ります。typle-r は LocalStorage に置きますが、ここではサーバーに置く点が違います（Cookie を消すと失われるのは同じ）。
- **ログイン**: typle-r（v2.59.0 から）と同じく、Sparklingstadt ID と GitHub だけです（OmniAuth。セッションは Rails 8 の authentication）。
  - **Sparklingstadt ID**（`https://id.sparklingstadt.com`、OpenID Connect）: `omniauth_openid_connect` の戦略 `sid`（`config/initializers/omniauth.rb`）。発行元の discovery、PKCE（S256）・state・nonce 付きの認可コード、scope は `openid email profile`。ID トークンは署名（ID サーバーの JWKS。クライアントシークレットでの署名や `none` は受け付けない）・`iss`・`aud`・`exp`・`nonce` を確かめます。`email_verified` が true でない ID と、`sub` が `[a-z0-9]{1,64}` でない ID は断ります。名前は ID の `name`、空ならメールアドレスの `@` の前（画像はなし）。
  - ログインで開くアカウントは、その `sub` をひも付けたアカウント（`users.sid_sub`、下の `sid:link`）か、なければその `sub` のアカウント（typle-r の `sid:<sub>`。最初のログインで作る）です。ひも付けを読めないときはログインを失敗にし、空のアカウントは開きません。
  - ログアウト（すべての端末からのログアウトも）のあとは、Cookie `typle-sid-relogin`（HttpOnly・SameSite=Lax・https では Secure・30日）を置き、次の Sparklingstadt ID のログインで `prompt=login` を付けてパスワードを聞きます。ログインできたら消します。
  - ID とパスワードのログイン（登録・パスワードを忘れた・再設定・ID を忘れた・メールアドレスの確認・パスワードの変更・メール）は typle-r #377 と同じく外しました。そのアカウントとデータは DB に残りますが、ログインはできません（GitHub と連携していたものは GitHub で入れます）。
- **Handwriting**: 手書きの言語の印が付いたリストで使えます。OS の手書き入力で入力欄に書くか、韓国語のリストではアプリの手書きパッドに書きます。パッドは PaddleOCR の韓国語の認識モデルを onnxruntime-web でブラウザーの中で動かし、お手本に寄せた判定（CTC の前向きアルゴリズム、差が 3 以内なら受け入れ）も typle-r と同じです。

## デザイン

UI は Tailwind CSS v4 と daisyUI 5 で作っています。Node は使いません。

- **daisyUI の組み込み**：`app/assets/tailwind/daisyui.mjs` / `daisyui-theme.mjs` は daisyUI のスタンドアロン版（5.8.2）で、`tailwindcss-rails` がそのまま読み込みます。更新するときは daisyUI のリリースから同じ名前のファイルを取り直します。
- **テーマ**：`app/assets/tailwind/application.css` で、明るい `typle` と暗い `typle-dark` の2つを定義しています。トップバーのボタン（`theme_controller.js`）が `<html data-theme>` を切り替えます。
- **色**：ビューでは daisyUI の色の名前を使います（`base-100/200/300`、`base-content`、`primary`、`success`、`warning`、`error`、`info`）。
- **アイコンとフォント**：lucide のアイコンと Noto Sans JP を使います。

- 文言の多くは typle-r の `src/messages` をそのまま使います（`config/locales/typle/`、ICU の `{name}`・plural を Rails の形に直したもの。ビューでは `tt("practice.result.title")` のように読みます）
- `app/components/ui/`（ViewComponent）と `app/helpers/ui_helper.rb`：ボタン・カード・バッジ・入力欄・トグル・表などの部品です。中身は daisyUI のクラス（`btn`、`card`、`badge`、`input`、`toggle`、`table`、`modal` など）で、`Ui::Classes` に集めています。ページから渡すクラスとの重なりは `cn`（tailwind_merge）で解きます
- `app/views/layouts/application/`: トップバー・サイドバー・ドロワー（typle-r の Navbar・Sidebar・MobileNav）
- 画面ごとの追加の部品は `app/helpers/*_design_helper.rb`、文言は `config/locales/design/*.yml`（多くは typle-r の `src/messages` から取り込み）
- CSS は `bin/rails tailwindcss:build` で `app/assets/builds/tailwind.css` に作ります。開発中は Puma が監視して作り直します
- テーマはトップバーの太陽・月のボタンで切り替え、typle-r と同じ `typle-r:theme:v1` に保存します

## 設定（環境変数）

| 名前 | 内容 |
|---|---|
| `SID_ISSUER`・`SID_CLIENT_ID`・`SID_CLIENT_SECRET` | Sparklingstadt ID のクライアント。発行元は `https://id.sparklingstadt.com`、リダイレクト URI は `<オリジン>/auth/sid/callback`。3つそろったときだけ Sparklingstadt ID のボタンを出します |
| `GITHUB_CLIENT_ID`・`GITHUB_CLIENT_SECRET` | GitHub の OAuth App。コールバック URL は `<オリジン>/auth/github/callback`。ないときは GitHub のボタンを出しません |
| `LOCAL_DEVELOPMENT_LOGIN` | `1` で開発用のデモアカウントのログインを出す（development 環境で、このマシンからのアクセスだけ） |

どちらのログインもないときは、ログイン画面に「ログイン機能を利用できません」と出します。

## Sparklingstadt ID と今のアカウントをひも付ける

typle-r の `npm run sid:link -- <sub> <account>` に当たるコマンドです。ひも付けると、その Sparklingstadt ID でログインしたときに今のアカウント（GitHub のアカウントや、ID とパスワードで作ったアカウント）のデータが開きます。

1. 自分の `sub` を調べる: 一度 Sparklingstadt ID でログインし、何も保存しないうちにログアウトしてから、`bin/rails runner 'puts User.where.not(sid_sub: nil).order(:created_at).last(5).map { [_1.sid_sub, _1.name, _1.created_at].join(" ") }'` で、いまログインした ID の行（名前と時刻）を探します（`sub` は Sparklingstadt ID の設定画面などに出ていればそれでも構いません）
2. ひも付け先のアカウントを決める: ログイン ID（GitHub のアカウントは GitHub のユーザー名を元にした ID）か `github:<GitHub のユーザー ID（数字）>`
3. `bin/rails "sid:link[<sub>,<アカウント>]"` を実行する（`sub` は `sid:<sub>` の形でも構いません）。本番の DB には本番の `DATABASE_URL` を渡して `RAILS_ENV=production` で実行します。結果に、書き込んだ DB（アダプターとホスト・DB 名）を出します

断るとき（終了コード 1）: その `sub` がもうほかのアカウントにひも付いている、そのアカウントにもう別の `sub` がある、そのアカウントがないか保存したデータ（パック・リスト・練習記録・端末）がない（打ち間違いの防止）、その `sub` のアカウント（最初のログインで作ったもの）にもう保存したデータがある（ひも付けると読めなくなるため）。その `sub` のアカウントが空なら、ひも付けるときに消します。

## コードの場所

- 公式パック: `db/official_lists/`（typle-r の `src/lib/packs/commands/` の写し、順番は `manifest.json`）と `app/models/official_catalog.rb`
- 文字の判定: `app/javascript/typing.js`（typle-r の `src/lib/typing.ts`）、手書きの照合: `app/javascript/writing.js`（`src/lib/writing.ts`）、手書きの認識: `app/javascript/handwriting.js`（`src/lib/handwriting.ts`・`handwritingRecognizer.ts`）
- 練習の画面: `app/javascript/controllers/practice_controller.js`・`writing_controller.js`
- 手書きパッドのモデルと実行環境: `public/handwriting/`（`ko/` のモデルは PaddleOCR、Apache License 2.0。`ort/` は onnxruntime-web 1.31.1、MIT）
- 文言: `config/locales/<言語>.yml`（ja が基準）。テストと開発では足りない訳があるとエラーになります

## typle-r との違い

- ゲストのデータはブラウザーの LocalStorage ではなく、Cookie で結び付けたサーバーのデータです
- パックのファイル（`.typle-pack.json`）の取り込み・書き出し、公式パックの個別ページ（`/packs/<slug>`）、X へのシェア、OGP 画像、アクセス解析はありません
- 単語の編集は行ごとの入力欄（追加・削除・並べ替え・Enter・Alt+↑↓・Ctrl+Enter・CSV の読み込み）。typle-r の読み込みダイアログ（プレビュー・置き換え）はなく、末尾に追加します
- パックはリストから作ります（typle-r と同じ）。パックのカテゴリ・タグの欄はなく、リストのものを表示します
- 練習の途中で別のリストを選んでも確認しません
