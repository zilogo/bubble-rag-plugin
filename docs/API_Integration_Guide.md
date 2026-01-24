# Bubble RAG API 集成文档

## 目录
- [1. 概述](#1-概述)
- [2. 快速开始](#2-快速开始)
- [3. 认证说明](#3-认证说明)
- [4. 接口列表](#4-接口列表)
  - [4.1 用户登录/注册](#41-用户登录注册)
  - [4.2 创建知识库](#42-创建知识库)
  - [4.3 查询知识库列表](#43-查询知识库列表)
  - [4.4 更新知识库](#44-更新知识库)
  - [4.5 删除知识库](#45-删除知识库)
  - [4.6 添加文档任务](#46-添加文档任务)
  - [4.7 查询文档任务列表](#47-查询文档任务列表)
  - [4.8 删除文档任务](#48-删除文档任务)
  - [4.9 聊天检索](#49-聊天检索)
- [5. 完整使用示例](#5-完整使用示例)
- [6. 错误处理](#6-错误处理)
- [7. 常见问题](#7-常见问题)

---

## 1. 概述

Bubble RAG API 提供了文档管理和智能检索功能，支持文档上传、解析、语义分割和基于知识库的智能问答。

**基础信息：**
- 基础URL: `http://172.16.13.88:8000`
- API前缀: `/bubble_rag/api/v1`
- 协议: HTTP
- 数据格式: JSON / Multipart Form-Data

**推荐模型配置：**
- Rerank模型ID: `154605956896915473` (Qwen3-Reranker-4B)
- Embedding模型ID: `154605669335433233` (Qwen3-Embedding-0.6B)

---

## 2. 快速开始

### 2.1 获取访问Token

首先调用登录接口获取Token：

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/auth/login_or_create' \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "your_username",
    "user_password": "your_password"
  }'
```

### 2.2 使用Token调用其他接口

将获取的Token放入请求头：

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/knowledge_base/list_knowledge_base' \
  -H 'Authorization: Bearer <your_token>' \
  -H 'x-token: <your_token>' \
  -H 'Content-Type: application/json' \
  -d '{"page_num": 1, "page_size": 10}'
```

---

## 3. 认证说明

### 3.1 获取Token

通过 `/auth/login_or_create` 接口获取JWT Token。

### 3.2 使用Token

在所有需要认证的接口请求头中添加：

```http
Authorization: Bearer <your_token>
x-token: <your_token>
```

### 3.3 Token有效期

Token默认有效期较长，建议定期刷新。

---

## 4. 接口列表

### 4.1 用户登录/注册

用户存在则登录，不存在则自动创建并登录。

#### 接口信息
- **URL**: `/bubble_rag/api/v1/auth/login_or_create`
- **方法**: `POST`
- **Content-Type**: `application/json`
- **需要认证**: 否

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| username | String | 是 | 用户名 |
| user_password | String | 否 | 密码，默认 `laiye123` |

#### 请求示例

```json
{
  "username": "api_user",
  "user_password": "mypassword123"
}
```

#### 响应示例

```json
{
  "msg": "success",
  "code": 200,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "username": "api_user",
    "user_role": "user",
    "display_name": "api_user"
  }
}
```

#### cURL 示例

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/auth/login_or_create' \
  -H 'Content-Type: application/json' \
  -d '{
    "username": "api_user",
    "user_password": "mypassword123"
  }'
```

---

### 4.2 创建知识库

创建一个新的知识库用于存储和管理文档。

#### 接口信息
- **URL**: `/bubble_rag/api/v1/knowledge_base/add_knowledge_base`
- **方法**: `POST`
- **Content-Type**: `application/json`
- **需要认证**: 是

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| kb_name | String | 是 | 知识库名称，建议使用唯一名称 |
| rerank_model_id | String | 是 | Rerank模型ID，推荐值：`154605956896915473` |
| embedding_model_id | String | 是 | Embedding模型ID，推荐值：`154605669335433233` |
| kb_desc | String | 否 | 知识库描述 |

#### 请求示例

```json
{
  "kb_name": "我的知识库",
  "rerank_model_id": "154605956896915473",
  "embedding_model_id": "154605669335433233",
  "kb_desc": "用于存储产品文档"
}
```

#### 响应示例

```json
{
  "msg": "success",
  "code": 200,
  "data": {
    "id": "155878243264626698",
    "kb_name": "我的知识库",
    "vector_id": "155878243264692234",
    "coll_name": "nJxLJsqqjCvvAXxQ",
    "rerank_model_id": "154605956896915473",
    "embedding_model_id": "154605669335433233",
    "kb_desc": "用于存储产品文档",
    "create_time": "2025-12-11T16:31:13",
    "update_time": "2025-12-11T16:31:13"
  }
}
```

#### cURL 示例

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/knowledge_base/add_knowledge_base' \
  -H 'Authorization: Bearer <your_token>' \
  -H 'x-token: <your_token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "kb_name": "我的知识库",
    "rerank_model_id": "154605956896915473",
    "embedding_model_id": "154605669335433233",
    "kb_desc": "用于存储产品文档"
  }'
```

#### 重要提示

1. **知识库名称唯一性**：建议使用时间戳或UUID确保名称唯一
2. **保存知识库ID**：创建成功后请保存返回的 `id`，后续操作都需要使用

---

### 4.3 查询知识库列表

查询当前用户的所有知识库。

#### 接口信息
- **URL**: `/bubble_rag/api/v1/knowledge_base/list_knowledge_base`
- **方法**: `POST`
- **Content-Type**: `application/json`
- **需要认证**: 是

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| kb_name | String | 否 | 知识库名称（模糊搜索） |
| page_num | Integer | 否 | 页码，默认1 |
| page_size | Integer | 否 | 每页数量，默认20 |

#### 请求示例

```json
{
  "kb_name": "",
  "page_num": 1,
  "page_size": 10
}
```

#### 响应示例

```json
{
  "msg": "success",
  "code": 200,
  "data": {
    "items": [
      {
        "id": "155878243264626698",
        "kb_name": "我的知识库",
        "coll_name": "nJxLJsqqjCvvAXxQ",
        "vector_id": "155878243264692234",
        "rerank_model_id": "154605956896915473",
        "embedding_model_id": "154605669335433233",
        "kb_desc": "用于存储产品文档",
        "create_time": "2025-12-11T16:31:13",
        "update_time": "2025-12-11T16:31:13",
        "benchmark_status": 1,
        "global_benchmark_progress": 100
      }
    ],
    "total": 1,
    "page": 1,
    "page_size": 10,
    "total_pages": 1
  }
}
```

#### cURL 示例

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/knowledge_base/list_knowledge_base' \
  -H 'Authorization: Bearer <your_token>' \
  -H 'x-token: <your_token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "kb_name": "",
    "page_num": 1,
    "page_size": 10
  }'
```

---

### 4.4 更新知识库

更新知识库的名称、描述或模型配置。

#### 接口信息
- **URL**: `/bubble_rag/api/v1/knowledge_base/update_knowledge_base`
- **方法**: `POST`
- **Content-Type**: `application/json`
- **需要认证**: 是

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| kb_id | String | 是 | 知识库ID（**注意：参数名是 kb_id 不是 id**） |
| kb_name | String | 否 | 新的知识库名称 |
| kb_desc | String | 否 | 新的知识库描述 |
| rerank_model_id | String | 否 | Rerank模型ID |
| embedding_model_id | String | 否 | Embedding模型ID |

#### 请求示例

**只更新名称：**
```json
{
  "kb_id": "155878243264626698",
  "kb_name": "新的知识库名称"
}
```

**更新名称和描述：**
```json
{
  "kb_id": "155878243264626698",
  "kb_name": "产品文档知识库",
  "kb_desc": "包含所有产品相关文档"
}
```

**完整更新（包含模型）：**
```json
{
  "kb_id": "155878243264626698",
  "kb_name": "技术文档库",
  "kb_desc": "技术支持文档",
  "rerank_model_id": "154605956896915473",
  "embedding_model_id": "154605669335433233"
}
```

#### 响应示例

```json
{
  "msg": "知识库更新成功",
  "code": 200,
  "data": {
    "id": "155878243264626698",
    "kb_name": "新的知识库名称",
    "kb_desc": "新的描述信息",
    "rerank_model_id": "154605956896915473",
    "embedding_model_id": "154605669335433233",
    "vector_id": "155878243264692234",
    "coll_name": "nJxLJsqqjCvvAXxQ",
    "create_time": "2025-12-11T16:31:13",
    "update_time": "2026-01-24T18:05:23"
  }
}
```

#### cURL 示例

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/knowledge_base/update_knowledge_base' \
  -H 'Authorization: Bearer <your_token>' \
  -H 'x-token: <your_token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "kb_id": "155878243264626698",
    "kb_name": "新的知识库名称",
    "kb_desc": "新的描述信息"
  }'
```

#### 重要提示

1. **参数名称**：必须使用 `kb_id`，不能使用 `id`
2. **部分更新**：只传需要更新的字段即可，不需要传所有字段
3. **模型ID**：如果不更改模型配置，可以不传模型ID参数

#### 常见错误

| 错误信息 | 原因 | 解决方案 |
|----------|------|----------|
| `知识库ID不能为空` | 参数名使用了 `id` 而不是 `kb_id` | 改为 `kb_id` |
| `知识库不存在` | kb_id 无效或不存在 | 检查知识库ID是否正确 |

---

### 4.5 删除知识库

删除指定的知识库及其所有文档数据。

#### 接口信息
- **URL**: `/bubble_rag/api/v1/knowledge_base/delete_knowledge_base`
- **方法**: `POST`
- **Content-Type**: `application/json`
- **需要认证**: 是

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| kb_id | String | 是 | 要删除的知识库ID |

#### 请求示例

```json
{
  "kb_id": "155878243264626698"
}
```

#### 响应示例

```json
{
  "msg": "success",
  "code": 200,
  "data": null
}
```

#### cURL 示例

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/knowledge_base/delete_knowledge_base' \
  -H 'Authorization: Bearer <your_token>' \
  -H 'x-token: <your_token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "kb_id": "155878243264626698"
  }'
```

#### 重要警告

> **删除操作不可恢复！** 删除知识库会同时删除：
> - 知识库本身
> - 所有关联的文档
> - 所有向量数据和元数据

---

### 4.6 添加文档任务

上传文档到知识库并启动解析任务。

#### 接口信息
- **URL**: `/bubble_rag/api/v1/documents/add_doc_task`
- **方法**: `POST`
- **Content-Type**: `multipart/form-data`
- **需要认证**: 是

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| files | File | 是 | 上传的文档文件（支持.txt, .docx, .pdf等） |
| doc_knowledge_base_id | String | 是 | 知识库ID |
| chunk_size | Integer | 否 | 文本分块大小，默认1000 |
| data_clean | Integer | 否 | 是否数据清洗，0=否，1=是，默认1 |
| semantic_split | Integer | 否 | 是否语义分割，0=否，1=是，默认1 |
| small2big | Integer | 否 | 是否小到大策略，0=否，1=是，默认1 |
| graphing | Integer | 否 | 是否构建图谱，0=否，1=是，默认0 |

#### 响应示例

```json
{
  "msg": "success",
  "code": 200,
  "data": [
    {
      "id": "155878462324736010",
      "file_id": "155878462307958794",
      "doc_knowledge_base_id": "155878243264626698",
      "total_file": 1,
      "remaining_file": 1,
      "success_file": 0,
      "split_status": -1,
      "curr_file_progress": 0,
      "curr_filename": "",
      "content_length": 0,
      "chunk_size": 1000,
      "data_clean": 1,
      "semantic_split": 1,
      "small2big": 1,
      "graphing": 0,
      "create_time": "2025-12-11T16:33:24",
      "update_time": "2025-12-11T16:33:24"
    }
  ]
}
```

#### 响应字段说明

| 字段 | 说明 |
|------|------|
| id | 任务ID |
| file_id | 文件ID |
| split_status | 分割状态：-1=处理中，1=完成 |
| curr_file_progress | 当前文件处理进度（0-100） |
| content_length | 文档内容长度（字符数） |

#### cURL 示例

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/documents/add_doc_task' \
  -H 'Authorization: Bearer <your_token>' \
  -H 'x-token: <your_token>' \
  -F 'files=@/path/to/document.txt' \
  -F 'doc_knowledge_base_id=155878243264626698' \
  -F 'chunk_size=1000' \
  -F 'data_clean=1' \
  -F 'semantic_split=1' \
  -F 'small2big=1' \
  -F 'graphing=0'
```

---

### 4.7 查询文档任务列表

查询知识库中文档任务的处理状态。

#### 接口信息
- **URL**: `/bubble_rag/api/v1/documents/list_doc_tasks`
- **方法**: `POST`
- **Content-Type**: `application/json`
- **需要认证**: 是

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| doc_knowledge_base_id | String | 是 | 知识库ID |
| page_num | Integer | 否 | 页码，默认1 |
| page_size | Integer | 否 | 每页数量，默认10 |

#### 请求示例

```json
{
  "doc_knowledge_base_id": "155878243264626698",
  "page_num": 1,
  "page_size": 10
}
```

#### 响应示例

```json
{
  "msg": "success",
  "code": 200,
  "data": {
    "items": [
      {
        "id": "155878462324736010",
        "file_id": "155878462307958794",
        "doc_knowledge_base_id": "155878243264626698",
        "curr_filename": "document.txt",
        "total_file": 1,
        "remaining_file": 0,
        "success_file": 1,
        "split_status": 1,
        "curr_file_progress": 100,
        "content_length": 1234,
        "segmented_index": 1234,
        "chunk_size": 1000,
        "data_clean": 1,
        "semantic_split": 1,
        "small2big": 1,
        "graphing": 0,
        "create_time": "2025-12-11T16:33:24",
        "update_time": "2025-12-11T16:34:15"
      }
    ],
    "total": 1,
    "page": 1,
    "page_size": 10,
    "total_pages": 1
  }
}
```

#### 判断文档处理完成

当满足以下条件时，表示文档处理完成：
- `split_status` = 1
- `curr_file_progress` = 100

#### cURL 示例

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/documents/list_doc_tasks' \
  -H 'Authorization: Bearer <your_token>' \
  -H 'x-token: <your_token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "doc_knowledge_base_id": "155878243264626698",
    "page_num": 1,
    "page_size": 10
  }'
```

---

### 4.8 删除文档任务

删除知识库中的文档任务及其关联的向量数据。

#### 接口信息
- **URL**: `/bubble_rag/api/v1/documents/delete_doc_task`
- **方法**: `POST`
- **Content-Type**: `application/json`
- **需要认证**: 是

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| task_ids | Array[String] | 是 | 要删除的任务ID列表（**注意：必须是数组格式**） |
| doc_knowledge_base_id | String | 是 | 知识库ID |

#### 请求示例

```json
{
  "task_ids": ["162238344535736330"],
  "doc_knowledge_base_id": "162238319369912330"
}
```

#### 响应示例

```json
{
  "msg": "success",
  "code": 200,
  "data": null
}
```

#### cURL 示例

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/documents/delete_doc_task' \
  -H 'Authorization: Bearer <your_token>' \
  -H 'x-token: <your_token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "task_ids": ["162238344535736330"],
    "doc_knowledge_base_id": "162238319369912330"
  }'
```

#### 重要提示

1. **参数格式**：`task_ids` 必须是数组格式，即使只删除一个任务也要使用 `["task_id"]`
2. **任务ID获取**：任务ID可从上传文档响应或查询任务列表中获取（`id` 字段）
3. **删除不可恢复**：删除操作会同时删除：
   - 文档任务记录
   - 文档解析内容
   - 关联的向量数据

#### 常见错误

| 错误信息 | 原因 | 解决方案 |
|----------|------|----------|
| `task_ids不能为空` | 未提供 task_ids 或格式错误 | 确保使用数组格式 `["id"]` |
| `知识库不存在` | doc_knowledge_base_id 无效 | 检查知识库ID是否正确 |
| `文档片段不存在` | 使用了错误的端点或参数名 | 使用 `/delete_doc_task` 端点和 `task_ids` 参数 |

---

### 4.9 聊天检索

基于知识库进行智能问答检索。

#### 接口信息
- **URL**: `/bubble_rag/api/v1/chat/completions`
- **方法**: `POST`
- **Content-Type**: `application/json`
- **需要认证**: 是

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| messages | Array | 是 | 消息列表，包含role和content |
| doc_knowledge_base_id | String | 是 | 知识库ID |
| limit_result | Integer | 否 | 返回结果数限制，默认5 |
| graphing | Boolean | 否 | 是否使用图谱检索，**建议设为false** |
| stream | Boolean | 否 | 是否流式返回，默认false |
| temperature | Float | 否 | 生成温度，0-2，默认0.7 |
| max_tokens | Integer | 否 | 最大生成token数，默认2000，**支持最大32000+** |

#### 请求示例

```json
{
  "messages": [
    {
      "role": "user",
      "content": "这个文档主要讲什么？"
    }
  ],
  "doc_knowledge_base_id": "155878243264626698",
  "limit_result": 5,
  "graphing": false,
  "stream": false,
  "temperature": 0.7,
  "max_tokens": 2000
}
```

#### 响应示例

```json
{
  "id": "chatcmpl-01de8441f9bf44c098e5421164ea5",
  "object": "chat.completion",
  "created": 1765503041,
  "model": "Qwen3-32B",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "根据知识库中的文档，主要内容包括...",
        "name": null
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 270,
    "completion_tokens": 484,
    "total_tokens": 754
  },
  "system_fingerprint": null
}
```

#### 响应字段说明

| 字段 | 说明 |
|------|------|
| id | 会话ID |
| choices | 回答选项列表 |
| message.content | AI生成的回答内容 |
| finish_reason | 完成原因：stop=正常结束 |
| usage.prompt_tokens | 输入token数 |
| usage.completion_tokens | 输出token数 |
| usage.total_tokens | 总token数 |

#### cURL 示例

```bash
curl -X POST 'http://172.16.13.88:8000/bubble_rag/api/v1/chat/completions' \
  -H 'Authorization: Bearer <your_token>' \
  -H 'x-token: <your_token>' \
  -H 'Content-Type: application/json' \
  -d '{
    "messages": [{"role": "user", "content": "这个文档主要讲什么？"}],
    "doc_knowledge_base_id": "155878243264626698",
    "limit_result": 5,
    "graphing": false,
    "stream": false,
    "temperature": 0.7,
    "max_tokens": 2000
  }'
```

#### 重要提示

1. **等待文档处理完成**：确保文档任务的 `split_status=1` 后再进行检索
2. **graphing参数**：建议设为 `false`，除非已配置图谱服务
3. **max_tokens 配置**：根据不同场景选择合适的值（详见下方说明）

#### max_tokens 参数详解

**支持范围**：经过测试验证，API 支持最大至 32000+ tokens

| 场景 | 推荐值 | 说明 |
|------|--------|------|
| 短回答 | 500-1000 | 适用于简单问答 |
| 中等回答 | 2000-4000 | 适用于一般性分析 |
| 长回答/详细分析 | 8000-16000 | 适用于深度分析、长文档生成 |
| 极长输出 | 16000-32000 | 适用于完整报告生成 |

**测试结果：**

| max_tokens 设置 | 测试状态 | 实际生成范围 | 备注 |
|----------------|---------|-------------|------|
| 100 | ✅ 支持 | ~100 | 会达到上限截断 |
| 500 | ✅ 支持 | ~500 | 会达到上限截断 |
| 2000 (默认) | ✅ 支持 | ~1500-2000 | 推荐默认值 |
| 8000 | ✅ 支持 | ~1800-8000 | **与其他系统对齐** |
| 8192 | ✅ 支持 | 正常 | 标准上下文窗口 |
| 16384 | ✅ 支持 | 正常 | 大型上下文窗口 |
| 32000 | ✅ 支持 | 正常 | 测试通过 |

**使用建议：**

```json
// 短回答场景
{
  "max_tokens": 1000,
  "temperature": 0.7
}

// 标准场景（推荐）
{
  "max_tokens": 8000,
  "temperature": 0.7
}

// 长文档生成
{
  "max_tokens": 16000,
  "temperature": 0.5
}
```

**注意事项：**
- 实际生成的 tokens 数取决于问题复杂度和检索内容
- 更大的 max_tokens 会消耗更多时间和资源
- 建议根据实际需求设置，避免不必要的资源浪费

---

## 5. 完整使用示例

### Python SDK 示例

```python
import requests
import time

class BubbleRAGClient:
    def __init__(self, base_url="http://172.16.13.88:8000"):
        self.base_url = base_url
        self.api_prefix = "/bubble_rag/api/v1"
        self.token = None

    def _get_headers(self):
        headers = {"Content-Type": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
            headers["x-token"] = self.token
        return headers

    def login(self, username, password="laiye123"):
        """登录或注册"""
        url = f"{self.base_url}{self.api_prefix}/auth/login_or_create"
        payload = {"username": username, "user_password": password}
        response = requests.post(url, json=payload)
        result = response.json()
        if result.get("code") == 200:
            self.token = result["data"]["token"]
            print(f"登录成功: {username}")
            return True
        print(f"登录失败: {result.get('msg')}")
        return False

    def create_knowledge_base(self, kb_name, kb_desc="",
                              rerank_model_id="154605956896915473",
                              embedding_model_id="154605669335433233"):
        """创建知识库"""
        url = f"{self.base_url}{self.api_prefix}/knowledge_base/add_knowledge_base"
        payload = {
            "kb_name": kb_name,
            "rerank_model_id": rerank_model_id,
            "embedding_model_id": embedding_model_id,
            "kb_desc": kb_desc
        }
        response = requests.post(url, json=payload, headers=self._get_headers())
        result = response.json()
        if result.get("code") == 200:
            kb_id = result["data"]["id"]
            print(f"知识库创建成功: {kb_name} (ID: {kb_id})")
            return kb_id
        print(f"创建失败: {result.get('msg')}")
        return None

    def list_knowledge_bases(self, page_num=1, page_size=10):
        """查询知识库列表"""
        url = f"{self.base_url}{self.api_prefix}/knowledge_base/list_knowledge_base"
        payload = {"kb_name": "", "page_num": page_num, "page_size": page_size}
        response = requests.post(url, json=payload, headers=self._get_headers())
        return response.json()

    def update_knowledge_base(self, kb_id, kb_name=None, kb_desc=None,
                             rerank_model_id=None, embedding_model_id=None):
        """更新知识库

        Args:
            kb_id: 知识库ID
            kb_name: 新的知识库名称（可选）
            kb_desc: 新的描述（可选）
            rerank_model_id: Rerank模型ID（可选）
            embedding_model_id: Embedding模型ID（可选）
        """
        url = f"{self.base_url}{self.api_prefix}/knowledge_base/update_knowledge_base"
        payload = {"kb_id": kb_id}

        # 只添加非空参数
        if kb_name is not None:
            payload["kb_name"] = kb_name
        if kb_desc is not None:
            payload["kb_desc"] = kb_desc
        if rerank_model_id is not None:
            payload["rerank_model_id"] = rerank_model_id
        if embedding_model_id is not None:
            payload["embedding_model_id"] = embedding_model_id

        response = requests.post(url, json=payload, headers=self._get_headers())
        result = response.json()
        if result.get("code") == 200:
            print(f"知识库更新成功: {kb_id}")
            return result["data"]
        print(f"更新失败: {result.get('msg')}")
        return None

    def delete_knowledge_base(self, kb_id):
        """删除知识库"""
        url = f"{self.base_url}{self.api_prefix}/knowledge_base/delete_knowledge_base"
        payload = {"kb_id": kb_id}
        response = requests.post(url, json=payload, headers=self._get_headers())
        result = response.json()
        if result.get("code") == 200:
            print(f"知识库删除成功: {kb_id}")
            return True
        print(f"删除失败: {result.get('msg')}")
        return False

    def upload_document(self, kb_id, file_path, chunk_size=1000):
        """上传文档"""
        url = f"{self.base_url}{self.api_prefix}/documents/add_doc_task"
        headers = {
            "Authorization": f"Bearer {self.token}",
            "x-token": self.token
        }
        files = {"files": open(file_path, "rb")}
        data = {
            "doc_knowledge_base_id": kb_id,
            "chunk_size": str(chunk_size),
            "data_clean": "1",
            "semantic_split": "1",
            "small2big": "1",
            "graphing": "0"
        }
        response = requests.post(url, files=files, data=data, headers=headers)
        result = response.json()
        if result.get("code") == 200:
            task_id = result["data"][0]["id"]
            print(f"文档上传成功，任务ID: {task_id}")
            return task_id
        print(f"上传失败: {result.get('msg')}")
        return None

    def get_task_status(self, kb_id):
        """查询文档任务状态"""
        url = f"{self.base_url}{self.api_prefix}/documents/list_doc_tasks"
        payload = {"doc_knowledge_base_id": kb_id, "page_num": 1, "page_size": 10}
        response = requests.post(url, json=payload, headers=self._get_headers())
        return response.json()

    def wait_for_completion(self, kb_id, timeout=300, interval=5):
        """等待文档处理完成"""
        start_time = time.time()
        while time.time() - start_time < timeout:
            result = self.get_task_status(kb_id)
            if result.get("code") == 200:
                items = result["data"]["items"]
                if items:
                    task = items[0]
                    if task["split_status"] == 1 and task["curr_file_progress"] == 100:
                        print("文档处理完成!")
                        return True
                    print(f"处理中... 进度: {task['curr_file_progress']}%")
            time.sleep(interval)
        print("等待超时")
        return False

    def delete_doc_task(self, kb_id, task_ids):
        """删除文档任务

        Args:
            kb_id: 知识库ID
            task_ids: 任务ID列表（单个ID也需要用列表包装）
        """
        url = f"{self.base_url}{self.api_prefix}/documents/delete_doc_task"
        # 确保 task_ids 是列表格式
        if isinstance(task_ids, str):
            task_ids = [task_ids]
        payload = {
            "task_ids": task_ids,
            "doc_knowledge_base_id": kb_id
        }
        response = requests.post(url, json=payload, headers=self._get_headers())
        result = response.json()
        if result.get("code") == 200:
            print(f"文档任务删除成功: {task_ids}")
            return True
        print(f"删除失败: {result.get('msg')}")
        return False

    def chat(self, kb_id, question, limit_result=5):
        """聊天检索"""
        url = f"{self.base_url}{self.api_prefix}/chat/completions"
        payload = {
            "messages": [{"role": "user", "content": question}],
            "doc_knowledge_base_id": kb_id,
            "limit_result": limit_result,
            "graphing": False,
            "stream": False,
            "temperature": 0.7,
            "max_tokens": 2000
        }
        response = requests.post(url, json=payload, headers=self._get_headers())
        result = response.json()
        if "choices" in result:
            return result["choices"][0]["message"]["content"]
        return f"检索错误: {result}"


# 使用示例
if __name__ == "__main__":
    client = BubbleRAGClient()

    # 1. 登录
    client.login("my_user", "my_password")

    # 2. 创建知识库
    kb_id = client.create_knowledge_base(
        kb_name=f"测试知识库_{int(time.time())}",
        kb_desc="API测试"
    )

    if kb_id:
        # 3. 上传文档
        task_id = client.upload_document(kb_id, "/path/to/document.txt")

        # 4. 等待处理完成
        if client.wait_for_completion(kb_id):
            # 5. 聊天检索
            answer = client.chat(kb_id, "文档的主要内容是什么？")
            print(f"\n回答: {answer}")

        # 6. 删除文档任务（可选）
        # client.delete_doc_task(kb_id, task_id)

        # 7. 删除知识库（可选）
        # client.delete_knowledge_base(kb_id)
```

---

## 6. 错误处理

### 常见错误码

| 错误码 | 说明 | 解决方案 |
|--------|------|----------|
| 200 | 成功 | - |
| 400 | 请求参数错误 | 检查请求参数格式和必填项 |
| 401 | 认证失败 | 检查Token是否正确或过期 |
| 403 | 无权限 | 检查是否有操作该资源的权限 |
| 404 | 资源不存在 | 检查知识库ID或文件ID是否正确 |
| 410 | 业务逻辑错误 | 查看msg字段的具体错误信息 |
| 500 | 服务器内部错误 | 联系技术支持 |

### 错误响应格式

```json
{
  "msg": "错误描述",
  "code": 400,
  "data": null
}
```

---

## 7. 常见问题

### Q1: 支持哪些文档格式？

支持常见文档格式：
- 文本文件：`.txt`
- Office文档：`.docx`, `.doc`
- PDF文档：`.pdf`

### Q2: 文档处理需要多长时间？

处理时间取决于：
- 文档大小
- 是否启用语义分割
- 系统负载

通常小文件（<1MB）在1-5分钟内完成。

### Q3: 如何判断文档处理完成？

查询任务状态时，满足以下条件表示完成：
- `split_status` = 1
- `curr_file_progress` = 100

### Q4: 检索结果不准确怎么办？

尝试调整以下参数：
- 增加 `limit_result` 获取更多结果
- 调整 `temperature` 控制生成随机性
- 调整文档分块大小 `chunk_size`

### Q5: Token如何获取和刷新？

通过 `/auth/login_or_create` 接口获取Token。Token有效期较长，如遇401错误请重新登录获取。

### Q6: graphing参数有什么作用？

`graphing` 用于启用知识图谱检索。建议设为 `false`，除非已配置图谱服务。

---

## 附录

### 测试脚本

```bash
#!/bin/bash
# test_api.sh - 快速测试API连通性

BASE_URL="http://172.16.13.88:8000"
API_PREFIX="/bubble_rag/api/v1"

echo "=== 测试登录 ==="
LOGIN_RESULT=$(curl -s -X POST "${BASE_URL}${API_PREFIX}/auth/login_or_create" \
  -H "Content-Type: application/json" \
  -d '{"username": "test_user", "user_password": "laiye123"}')

TOKEN=$(echo "$LOGIN_RESULT" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -n "$TOKEN" ]; then
    echo "登录成功，Token: ${TOKEN:0:50}..."

    echo -e "\n=== 测试查询知识库 ==="
    curl -s -X POST "${BASE_URL}${API_PREFIX}/knowledge_base/list_knowledge_base" \
      -H "Authorization: Bearer $TOKEN" \
      -H "x-token: $TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"page_num": 1, "page_size": 5}'
else
    echo "登录失败"
fi
```

### 完整流程测试脚本

```bash
#!/bin/bash
# test_full_flow.sh - 完整API流程测试（创建、上传、查询、删除）

BASE_URL="http://172.16.13.88:8000"
API_PREFIX="/bubble_rag/api/v1"

# 1. 登录
echo "=== 步骤1: 登录 ==="
LOGIN_RESULT=$(curl -s -X POST "${BASE_URL}${API_PREFIX}/auth/login_or_create" \
  -H "Content-Type: application/json" \
  -d '{"username": "api_test", "user_password": "laiye123"}')
TOKEN=$(echo "$LOGIN_RESULT" | jq -r '.data.token')
echo "登录成功"

# 2. 创建知识库
echo -e "\n=== 步骤2: 创建知识库 ==="
KB_RESULT=$(curl -s -X POST "${BASE_URL}${API_PREFIX}/knowledge_base/add_knowledge_base" \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"kb_name": "API_Test_KB", "rerank_model_id": "154605956896915473", "embedding_model_id": "154605669335433233", "kb_desc": "API测试"}')
KB_ID=$(echo "$KB_RESULT" | jq -r '.data.id')
echo "知识库创建成功: $KB_ID"

# 3. 创建并上传测试文件
echo -e "\n=== 步骤3: 上传文档 ==="
echo "这是一个测试文档，用于验证API功能。" > /tmp/test_doc.txt
UPLOAD_RESULT=$(curl -s -X POST "${BASE_URL}${API_PREFIX}/documents/add_doc_task" \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-token: $TOKEN" \
  -F "files=@/tmp/test_doc.txt" \
  -F "doc_knowledge_base_id=$KB_ID" \
  -F "chunk_size=500")
TASK_ID=$(echo "$UPLOAD_RESULT" | jq -r '.data[0].id')
echo "文档上传成功，任务ID: $TASK_ID"

# 4. 等待处理完成
echo -e "\n=== 步骤4: 等待处理 ==="
sleep 10
echo "处理完成"

# 5. 删除文档任务
echo -e "\n=== 步骤5: 删除文档任务 ==="
DELETE_RESULT=$(curl -s -X POST "${BASE_URL}${API_PREFIX}/documents/delete_doc_task" \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"task_ids\": [\"$TASK_ID\"], \"doc_knowledge_base_id\": \"$KB_ID\"}")
echo "$DELETE_RESULT" | jq .

# 6. 删除知识库
echo -e "\n=== 步骤6: 删除知识库 ==="
curl -s -X POST "${BASE_URL}${API_PREFIX}/knowledge_base/delete_knowledge_base" \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"kb_id\": \"$KB_ID\"}" | jq .

echo -e "\n=== 测试完成 ==="
```

---

**文档版本**: v2.2
**最后更新**: 2026-01-24
**适用环境**: `http://172.16.13.88:8000`

### 更新日志

| 版本 | 日期 | 更新内容 |
|------|------|----------|
| v2.2 | 2026-01-24 | 新增 4.4 更新知识库接口；更新 Python SDK 添加 update_knowledge_base() 方法；完善文档任务管理说明 |
| v2.1 | 2026-01-24 | 新增 4.8 删除文档任务接口；更新 Python SDK 示例；新增完整流程测试脚本 |
| v2.0 | 2025-12-12 | 初始版本 |
