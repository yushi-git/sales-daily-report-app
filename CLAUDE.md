# 使用技術
**言語** TypeScript
**フレームワーク** Next.js(App Router)
**UIコンポーネント** shadcn/ui + Tailwind CSS
**APIスキーマ定義** OpenAPI(Zodによる検証)
**DBスキーマ定義** Prisma.js
**テスト** Vitest
**デプロイ** Google Cloud Run


## 要件定義

### エンティティ概要

**日報 (DailyReport)** は1人の営業担当が1日1件作成します。日報には複数の訪問記録 (VisitRecord) が紐づき、各訪問には顧客と訪問内容を記録します。また、日報にはProblem/Planを記述するセクションがあり、上長はそれぞれにコメントを残せます。

### 主要エンティティ

- **Sales（営業マスタ）** — 営業担当者。日報を作成する。上長も同テーブルで管理（自己参照）
- **Customer（顧客マスタ）** — 訪問対象の顧客情報
- **DailyReport（日報）** — 営業が1日1件作成。作成日・ステータスを持つ
- **VisitRecord（訪問記録）** — 日報に紐づく訪問明細。顧客・訪問内容を複数行記録可能
- **ReportSection（Problem/Plan）** — 日報ごとのProblem・Planテキスト（種別カラムで区分）
- **SectionComment（上長コメント）** — ReportSectionに対する上長のコメント


### テーブル詳細の補足

**DAILY_REPORT.status** は `draft`（下書き）・`submitted`（提出済み）・`confirmed`（上長確認済み）などの値を想定しています。

**REPORT_SECTION.section_type** は `problem`・`plan` の2値で区分します。1日報につきそれぞれ1行ずつ持つ設計です（ユニーク制約：`daily_report_id + section_type`）。

**SALES の自己参照**（`manager_id FK → SALES.id`）により、同一テーブルで上長・部下の階層を表現しています。上長は `SECTION_COMMENT` を通じてコメントを残します。

**VISIT_RECORD.sort_order** で同一日報内の訪問順序を管理します。

---

## ER図

@doc/ER_DIAGRAM.md

## 画面設計

@doc/SCREEN_DESIGN.md

## API仕様書

@doc/API_SCHEME.md

## テスト仕様書

@doc/TEST_DEFINITION.md