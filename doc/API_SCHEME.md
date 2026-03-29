# 営業日報システム — API仕様書

---

## 目次

1. [共通仕様](#1-共通仕様)
2. [認証 API](#2-認証-api)
3. [日報 API](#3-日報-api)
4. [訪問記録 API](#4-訪問記録-api)
5. [レポートセクション API](#5-レポートセクション-api)
6. [セクションコメント API](#6-セクションコメント-api)
7. [顧客マスタ API](#7-顧客マスタ-api)
8. [営業マスタ API](#8-営業マスタ-api)
9. [エラーコード一覧](#9-エラーコード一覧)

---

## 1. 共通仕様

### ベース URL

```
https://api.example.com/v1
```

### 認証方式

JWT（JSON Web Token）を使用する。ログイン API で取得したトークンを、すべてのリクエストの `Authorization` ヘッダーに付与する。

```
Authorization: Bearer <token>
```

### リクエスト共通

| 項目 | 値 |
|------|----|
| Content-Type | `application/json` |
| Accept | `application/json` |
| 文字コード | UTF-8 |

### レスポンス共通形式

#### 成功時

```json
{
  "data": { ... },
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 100
  }
}
```

`meta` はページネーションが存在するエンドポイントのみ付与する。

#### エラー時

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力値が不正です",
    "details": [
      {
        "field": "email",
        "message": "メール形式で入力してください"
      }
    ]
  }
}
```

### ページネーション

一覧系 API はクエリパラメータでページネーションを指定する。

| パラメータ | 型 | デフォルト | 説明 |
|-----------|-----|-----------|------|
| `page` | integer | 1 | ページ番号 |
| `per_page` | integer | 20 | 1ページあたりの件数（最大100） |

### ロール

| ロール値 | 説明 |
|---------|------|
| `sales` | 営業担当者 |
| `manager` | 上長 |
| `admin` | 管理者 |

---

## 2. 認証 API

### POST /auth/login

ログインしてアクセストークンを取得する。

**リクエスト**

```json
{
  "email": "yamada@example.com",
  "password": "password123"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `email` | string | ○ | メールアドレス |
| `password` | string | ○ | パスワード（8文字以上） |

**レスポンス** `200 OK`

```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "Bearer",
    "expires_in": 86400,
    "user": {
      "id": "uuid-xxxx",
      "name": "山田 太郎",
      "email": "yamada@example.com",
      "role": "sales",
      "department": "東京営業部"
    }
  }
}
```

**エラー**

| ステータス | コード | 説明 |
|-----------|--------|------|
| 401 | `INVALID_CREDENTIALS` | メールアドレスまたはパスワードが不正 |
| 422 | `VALIDATION_ERROR` | 入力値不正 |

---

### POST /auth/logout

ログアウトしてトークンを無効化する。

**リクエスト** なし

**レスポンス** `204 No Content`

---

### GET /auth/me

ログイン中のユーザー情報を取得する。

**レスポンス** `200 OK`

```json
{
  "data": {
    "id": "uuid-xxxx",
    "name": "山田 太郎",
    "email": "yamada@example.com",
    "role": "sales",
    "department": "東京営業部",
    "manager": {
      "id": "uuid-yyyy",
      "name": "田中 部長"
    }
  }
}
```

---

## 3. 日報 API

### GET /reports

日報一覧を取得する。営業は自分の日報のみ取得可能。上長・管理者は部下・全員の日報も取得可能。

**クエリパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `sales_id` | string | — | 絞り込む営業担当者のID（上長・管理者のみ使用可） |
| `date_from` | string | — | 対象日の開始（`YYYY-MM-DD`） |
| `date_to` | string | — | 対象日の終了（`YYYY-MM-DD`） |
| `status` | string | — | ステータス（`draft` / `submitted` / `confirmed`） |
| `page` | integer | — | ページ番号（デフォルト: 1） |
| `per_page` | integer | — | 件数（デフォルト: 20） |

**レスポンス** `200 OK`

```json
{
  "data": [
    {
      "id": "uuid-xxxx",
      "report_date": "2025-04-01",
      "status": "submitted",
      "submitted_at": "2025-04-01T18:30:00+09:00",
      "created_at": "2025-04-01T17:00:00+09:00",
      "sales": {
        "id": "uuid-yyyy",
        "name": "山田 太郎"
      },
      "visit_count": 3
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 45
  }
}
```

---

### POST /reports

日報を新規作成する。同一担当者・同一日付の日報が既に存在する場合はエラー。

**権限** `sales` / `admin`

**リクエスト**

```json
{
  "report_date": "2025-04-01"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `report_date` | string | ○ | 対象日（`YYYY-MM-DD`） |

**レスポンス** `201 Created`

```json
{
  "data": {
    "id": "uuid-xxxx",
    "report_date": "2025-04-01",
    "status": "draft",
    "submitted_at": null,
    "created_at": "2025-04-01T09:00:00+09:00",
    "sales": {
      "id": "uuid-yyyy",
      "name": "山田 太郎"
    },
    "visit_count": 0
  }
}
```

**エラー**

| ステータス | コード | 説明 |
|-----------|--------|------|
| 409 | `DUPLICATE_REPORT` | 同日付の日報が既に存在する |
| 422 | `VALIDATION_ERROR` | 入力値不正 |

---

### GET /reports/:id

日報詳細を取得する。訪問記録・Problem/Plan・コメントを含む。

**レスポンス** `200 OK`

```json
{
  "data": {
    "id": "uuid-xxxx",
    "report_date": "2025-04-01",
    "status": "submitted",
    "submitted_at": "2025-04-01T18:30:00+09:00",
    "created_at": "2025-04-01T09:00:00+09:00",
    "sales": {
      "id": "uuid-yyyy",
      "name": "山田 太郎",
      "department": "東京営業部"
    },
    "visit_records": [
      {
        "id": "uuid-vr1",
        "sort_order": 1,
        "customer": {
          "id": "uuid-cust1",
          "name": "田中 一郎",
          "company": "株式会社〇〇"
        },
        "visit_content": "新製品の提案を実施。前向きな反応あり。次回見積提出へ。"
      }
    ],
    "sections": [
      {
        "id": "uuid-sec1",
        "section_type": "problem",
        "content": "競合他社の価格が下がっており、提案が難しい。",
        "updated_at": "2025-04-01T18:30:00+09:00",
        "comments": [
          {
            "id": "uuid-cmt1",
            "content": "価格交渉の余地があるか確認を。",
            "created_at": "2025-04-02T09:00:00+09:00",
            "commenter": {
              "id": "uuid-mgr1",
              "name": "田中 部長"
            }
          }
        ]
      },
      {
        "id": "uuid-sec2",
        "section_type": "plan",
        "content": "株式会社〇〇向けに見積書を作成して送付する。",
        "updated_at": "2025-04-01T18:30:00+09:00",
        "comments": []
      }
    ]
  }
}
```

**エラー**

| ステータス | コード | 説明 |
|-----------|--------|------|
| 403 | `FORBIDDEN` | アクセス権限なし |
| 404 | `NOT_FOUND` | 日報が存在しない |

---

### PATCH /reports/:id/submit

日報を提出する。ステータスを `submitted` に変更する。

**権限** 日報の作成者本人 / `admin`

**前提条件**
- ステータスが `draft` であること
- 訪問記録が1件以上あること
- Problem・Plan が入力済みであること

**リクエスト** なし

**レスポンス** `200 OK`

```json
{
  "data": {
    "id": "uuid-xxxx",
    "status": "submitted",
    "submitted_at": "2025-04-01T18:30:00+09:00"
  }
}
```

**エラー**

| ステータス | コード | 説明 |
|-----------|--------|------|
| 403 | `FORBIDDEN` | 操作権限なし |
| 422 | `INVALID_STATUS` | ステータスが `draft` でない |
| 422 | `MISSING_VISIT_RECORD` | 訪問記録が未登録 |
| 422 | `MISSING_SECTION` | Problem または Plan が未入力 |

---

### PATCH /reports/:id/confirm

日報を確認済みにする。ステータスを `confirmed` に変更する。

**権限** `manager` / `admin`

**前提条件**
- ステータスが `submitted` であること

**リクエスト** なし

**レスポンス** `200 OK`

```json
{
  "data": {
    "id": "uuid-xxxx",
    "status": "confirmed"
  }
}
```

**エラー**

| ステータス | コード | 説明 |
|-----------|--------|------|
| 403 | `FORBIDDEN` | 操作権限なし |
| 422 | `INVALID_STATUS` | ステータスが `submitted` でない |

---

### DELETE /reports/:id

日報を削除する。ステータスが `draft` の場合のみ削除可能。

**権限** 日報の作成者本人 / `admin`

**レスポンス** `204 No Content`

**エラー**

| ステータス | コード | 説明 |
|-----------|--------|------|
| 403 | `FORBIDDEN` | 操作権限なし |
| 422 | `INVALID_STATUS` | ステータスが `draft` でない |

---

## 4. 訪問記録 API

### GET /reports/:report_id/visit_records

指定した日報の訪問記録一覧を取得する。

**レスポンス** `200 OK`

```json
{
  "data": [
    {
      "id": "uuid-vr1",
      "sort_order": 1,
      "customer": {
        "id": "uuid-cust1",
        "name": "田中 一郎",
        "company": "株式会社〇〇"
      },
      "visit_content": "新製品の提案を実施。前向きな反応あり。",
      "created_at": "2025-04-01T17:00:00+09:00"
    }
  ]
}
```

---

### POST /reports/:report_id/visit_records

訪問記録を追加する。

**権限** 日報の作成者本人 / `admin`

**前提条件** 日報のステータスが `draft` であること

**リクエスト**

```json
{
  "customer_id": "uuid-cust1",
  "visit_content": "新製品の提案を実施。前向きな反応あり。",
  "sort_order": 1
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `customer_id` | string | ○ | 顧客ID |
| `visit_content` | string | ○ | 訪問内容（最大1000文字） |
| `sort_order` | integer | ○ | 表示順 |

**レスポンス** `201 Created`

```json
{
  "data": {
    "id": "uuid-vr1",
    "sort_order": 1,
    "customer": {
      "id": "uuid-cust1",
      "name": "田中 一郎",
      "company": "株式会社〇〇"
    },
    "visit_content": "新製品の提案を実施。前向きな反応あり。",
    "created_at": "2025-04-01T17:00:00+09:00"
  }
}
```

---

### PUT /reports/:report_id/visit_records/:id

訪問記録を更新する。

**権限** 日報の作成者本人 / `admin`

**前提条件** 日報のステータスが `draft` であること

**リクエスト**

```json
{
  "customer_id": "uuid-cust1",
  "visit_content": "更新後の訪問内容。",
  "sort_order": 1
}
```

**レスポンス** `200 OK`（POST と同形式）

---

### DELETE /reports/:report_id/visit_records/:id

訪問記録を削除する。

**権限** 日報の作成者本人 / `admin`

**前提条件** 日報のステータスが `draft` であること

**レスポンス** `204 No Content`

**エラー**

| ステータス | コード | 説明 |
|-----------|--------|------|
| 422 | `LAST_VISIT_RECORD` | 最後の1件は削除不可 |

---

## 5. レポートセクション API

### PUT /reports/:report_id/sections/:section_type

Problem または Plan の内容を更新する。`:section_type` は `problem` または `plan`。

**権限** 日報の作成者本人 / `admin`

**前提条件** 日報のステータスが `draft` であること

**リクエスト**

```json
{
  "content": "競合他社の価格が下がっており、提案が難しい。"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `content` | string | ○ | 本文（最大2000文字） |

**レスポンス** `200 OK`

```json
{
  "data": {
    "id": "uuid-sec1",
    "section_type": "problem",
    "content": "競合他社の価格が下がっており、提案が難しい。",
    "updated_at": "2025-04-01T17:30:00+09:00"
  }
}
```

---

## 6. セクションコメント API

### POST /sections/:section_id/comments

セクションにコメントを追加する。

**権限** `manager` / `admin`

**リクエスト**

```json
{
  "content": "価格交渉の余地があるか確認を。"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `content` | string | ○ | コメント本文（最大1000文字） |

**レスポンス** `201 Created`

```json
{
  "data": {
    "id": "uuid-cmt1",
    "content": "価格交渉の余地があるか確認を。",
    "created_at": "2025-04-02T09:00:00+09:00",
    "commenter": {
      "id": "uuid-mgr1",
      "name": "田中 部長"
    }
  }
}
```

---

### DELETE /sections/:section_id/comments/:id

コメントを削除する。自分が投稿したコメントのみ削除可能。

**権限** コメント投稿者本人 / `admin`

**レスポンス** `204 No Content`

---

## 7. 顧客マスタ API

### GET /customers

顧客一覧を取得する。

**クエリパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `q` | string | — | 顧客名・会社名の部分一致検索 |
| `page` | integer | — | ページ番号 |
| `per_page` | integer | — | 件数 |

**レスポンス** `200 OK`

```json
{
  "data": [
    {
      "id": "uuid-cust1",
      "name": "田中 一郎",
      "company": "株式会社〇〇",
      "phone": "03-1234-5678",
      "address": "東京都千代田区...",
      "created_at": "2024-01-15T09:00:00+09:00"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 80
  }
}
```

---

### POST /customers

顧客を新規登録する。

**権限** `admin`

**リクエスト**

```json
{
  "name": "田中 一郎",
  "company": "株式会社〇〇",
  "phone": "03-1234-5678",
  "address": "東京都千代田区..."
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `name` | string | ○ | 顧客名（最大100文字） |
| `company` | string | ○ | 会社名（最大200文字） |
| `phone` | string | — | 電話番号 |
| `address` | string | — | 住所（最大300文字） |

**レスポンス** `201 Created`（GET の単件と同形式）

---

### GET /customers/:id

顧客詳細を取得する。

**レスポンス** `200 OK`（一覧の1件と同形式）

---

### PUT /customers/:id

顧客情報を更新する。

**権限** `admin`

**リクエスト**（POST と同形式）

**レスポンス** `200 OK`（GET と同形式）

---

## 8. 営業マスタ API

### GET /sales

営業担当者一覧を取得する。

**権限** `manager`（自分の部下のみ） / `admin`（全件）

**クエリパラメータ**

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `page` | integer | — | ページ番号 |
| `per_page` | integer | — | 件数 |

**レスポンス** `200 OK`

```json
{
  "data": [
    {
      "id": "uuid-yyyy",
      "name": "山田 太郎",
      "email": "yamada@example.com",
      "department": "東京営業部",
      "role": "sales",
      "manager": {
        "id": "uuid-mgr1",
        "name": "田中 部長"
      },
      "created_at": "2024-01-10T09:00:00+09:00"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 15
  }
}
```

---

### POST /sales

営業担当者を新規登録する。

**権限** `admin`

**リクエスト**

```json
{
  "name": "山田 太郎",
  "email": "yamada@example.com",
  "password": "password123",
  "department": "東京営業部",
  "role": "sales",
  "manager_id": "uuid-mgr1"
}
```

| フィールド | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| `name` | string | ○ | 氏名（最大100文字） |
| `email` | string | ○ | メールアドレス（重複不可） |
| `password` | string | ○ | パスワード（8文字以上） |
| `department` | string | — | 部署（最大100文字） |
| `role` | string | ○ | ロール（`sales` / `manager` / `admin`） |
| `manager_id` | string | — | 上長のID（自分自身は指定不可） |

**レスポンス** `201 Created`（パスワードフィールドは含まない）

**エラー**

| ステータス | コード | 説明 |
|-----------|--------|------|
| 409 | `DUPLICATE_EMAIL` | メールアドレスが既に使用されている |
| 422 | `SELF_MANAGER` | 自分自身を上長に指定している |

---

### GET /sales/:id

営業担当者詳細を取得する。

**レスポンス** `200 OK`（一覧の1件と同形式）

---

### PUT /sales/:id

営業担当者情報を更新する。

**権限** `admin`

**リクエスト**

```json
{
  "name": "山田 太郎",
  "email": "yamada@example.com",
  "password": "",
  "department": "東京営業部",
  "role": "sales",
  "manager_id": "uuid-mgr1"
}
```

※ `password` が空文字の場合はパスワードを変更しない。

**レスポンス** `200 OK`（GET と同形式）

---

### DELETE /sales/:id

営業担当者を削除する。

**権限** `admin`

**レスポンス** `204 No Content`

**エラー**

| ステータス | コード | 説明 |
|-----------|--------|------|
| 422 | `HAS_REPORTS` | 日報が存在するため削除不可 |

---

## 9. エラーコード一覧

| HTTPステータス | コード | 説明 |
|--------------|--------|------|
| 400 | `BAD_REQUEST` | リクエスト形式が不正 |
| 401 | `UNAUTHORIZED` | 未認証（トークンなし・期限切れ） |
| 401 | `INVALID_CREDENTIALS` | メールアドレスまたはパスワードが不正 |
| 403 | `FORBIDDEN` | 操作権限なし |
| 404 | `NOT_FOUND` | リソースが存在しない |
| 409 | `DUPLICATE_REPORT` | 同日付の日報が既に存在する |
| 409 | `DUPLICATE_EMAIL` | メールアドレスが既に使用されている |
| 422 | `VALIDATION_ERROR` | 入力値不正（詳細は `details` 参照） |
| 422 | `INVALID_STATUS` | 不正なステータス遷移 |
| 422 | `MISSING_VISIT_RECORD` | 訪問記録が未登録 |
| 422 | `MISSING_SECTION` | Problem または Plan が未入力 |
| 422 | `LAST_VISIT_RECORD` | 最後の訪問記録は削除不可 |
| 422 | `SELF_MANAGER` | 自分自身を上長に指定している |
| 422 | `HAS_REPORTS` | 関連する日報が存在するため削除不可 |
| 500 | `INTERNAL_SERVER_ERROR` | サーバー内部エラー |
