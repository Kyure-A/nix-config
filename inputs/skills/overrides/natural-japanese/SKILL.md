---
name: natural-japanese
description: 日本語の文書・記事を新規執筆、推敲し、自然さと読みやすさを整える。文章の不自然さの診断・採点、本人の文章からの文体プロファイル作成にも使う。一般的な日本語の応答や、Markdown・章構成だけの整形には使わない。
license: MIT
argument-hint: "[write|score] [quick|full|exp] [対象ファイルや依頼内容]"
---

# natural-japanese

読み手が内容をつかめる日本語にする。元の事実、意味、書き手の声を保ち、効果のある箇所を直す。表現を一律に置換したり、短くするために必要な情報を落としたりしない。

このファイルが作業範囲と検査の深さを定める。補助資料からは定義・判定基準・例を必要に応じて参照し、旧 SKILL.md の節番号、固定工程、必須回数への指示はここで示す進め方に読み替える。

## 作業と深さを選ぶ

- `write [quick|full] <依頼や対象>`: 新規執筆または推敲。元の文章があるかと依頼内容から判断する。作業指定がなければこれを既定とする。
- `score [quick|full|exp] <対象>`: 診断のみ。書き換えはリライトの依頼があった場合に行う。自然言語での「AIっぽい？」「自然さを採点して」もこの扱いにする。
- 文体プロファイルの作成を求められた場合は、後述の資料を使う。

**quick（既定）**: 対象の長さと変更量に見合う確認で仕上げる。数文の推敲は目視の確認でよい。まとまった文章や同じ癖が繰り返される文章には lint を使う。必要な資料だけを読み、手順のための質問や検査を増やさない。

**full**: 全体の論旨、読みやすさ、文書の用途を含めて丁寧に見直す。明示指定を尊重し、長文や重要な文書でも必要性を判断して選ぶ。「ちゃんと」「しっかり」という語だけで固定の重い工程へ切り替えない。lint と、構造・用語の確認に役立つスクリプトを使う。独立した読み手の確認が有益な文書では追加レビューを利用できるが、文書の小ささや確認済みの事項を踏まえて作業量を調整する。

**exp** は明示的に求められた場合だけ使う意味的診断。`scripts/semantic.py` は実験的で、torch と sentence-transformers に依存し、初回に約1 GB のモデルを取得する。初回実行前にその負荷を知らせる。

## 書く・直す

与えられた素材から読者、用途、主メッセージをつかむ。不明点を質問するのは、答えによって内容が変わり、手元の資料からも判断できない場合。固有名詞、数値、引用、実例を補うときは出典を確かめ、推測を事実として書き足さない。

主張と根拠の関係、主語と述語、修飾先、文のつながりを明確にする。重要な部分に十分な説明を置き、専門用語は読者に必要な範囲で説明する。反復や前置き、翻訳調は、意味と文体を保って減らす。箇条書きは並列事項や手順など、読み取りやすくなる箇所に使う。

指定された形式や文体を優先する。見出しの結論化、強調、段落の長さなどを全箇所へ一律に適用しない。実用文に物語的な引きを足したり、根拠を超えた教訓で締めたりしない。

文書型が内容の抜けを見つける助けになる場合だけ、対応する資料を読む。

- 議事録: [minutes.md](references/doctypes/minutes.md)
- 調査・分析レポート: [report.md](references/doctypes/report.md)
- ガイド・マニュアル: [guide.md](references/doctypes/guide.md)
- メモ・企画書: [memo.md](references/doctypes/memo.md)
- スライド構成: [slide.md](references/doctypes/slide.md)

## 診断する

数値を返す前に [diagnose.md](references/diagnose.md) を読み、そこにある文字数の扱い、機械ベースの式、判断調整、バンドを使う。100 字未満は採点しない。高いほど自然な 0〜100 点の目安であり、AI が書いたかどうかの証明や確率ではない。

score の quick は lint に基づく機械ベースを使い、判断調整を加えない。full は構造、読みやすさ、用途の確認を加え、定義された範囲で判断調整を示す。exp は full に意味的診断を追加する。どの深さでも、実行できなかった検査を実行済みとして扱わず、機械ベースを取得できない場合は数値を作らず定性的な所見を返す。

結果はスコアの内訳、具体的な根拠、優先して直す箇所を中心に簡潔に示す。対象に問題がなければ、項目数を満たすための指摘を作らない。診断のために本文を書き換えたり、最後にリライトの確認質問を必ず置いたりする必要はない。

## 検査ツールと仕上げ

以下はスキルのディレクトリを基準にしたコマンド。対象ファイルには実際のパスを渡す。

```sh
uv run scripts/lint.py --json <file>
uv run scripts/outline.py <file>
uv run scripts/terms.py <file>
uv run scripts/semantic.py --json <file>
```

lint のジャンルが明確なら `--genre essay|tech|business` を指定する。比較が必要なら前回の JSON を `--baseline` に渡せる。finding があっても exit code は 0 なので、終了コードだけで問題なしと判定しない。入力エラーは exit code 1。

コマンドがなければ、対象プロジェクトの `devenv.nix` / `flake.nix` を確認して既存環境を使う。どちらもなければ `nix-shell` を使い、グローバルにはインストールしない。実行環境が使えない場合の目視確認には [manual-checklist.md](references/manual-checklist.md) を参照する。

finding は判断材料であり、機械的な修正指示ではない。文脈に合う表現は残す。修正後は変更箇所と前後のつながりを読み直し、検出結果に関わる変更をした場合は必要な検査を再実行する。好みの言い換えが往復するなら理由を整理して止める。重要な未解決点がなく、依頼した品質に達したら完成とする。

作業用 JSON や診断メモは一時ディレクトリに置く。納品物や依頼されたプロファイルを残し、自分で作った一時ファイルだけを片付ける。

## 必要なときに読む資料

- 改稿の判断、素材不足、繰り返す指摘: [revision-guide.md](references/revision-guide.md)
- 語順・係り受けの確認: [readability-principles.md](references/readability-principles.md)、[readability-antipatterns.md](references/readability-antipatterns.md)
- 表現の具体例: [forbidden-patterns.md](references/forbidden-patterns.md)、[translationese.md](references/translationese.md)、[examples.md](references/examples.md)
- 全体の文体やジャンル上の判断: [writing-constitution.md](references/writing-constitution.md)、[genre-notes.md](references/genre-notes.md)。数値目安や型は文脈を判断する材料とする。
- 本人の文体をプロファイル化する依頼: [style-profile-template.md](assets/style-profile-template.md)。提供された文章から傾向を抽出し、資料の量による不確実さを示す。既存の `style-profile.md` はユーザー指定の場所や対象プロジェクトで参照する。プロファイルの保存・更新は依頼の範囲で行い、個別の言い回しへの指摘を一般的な禁止規則へ広げない。
