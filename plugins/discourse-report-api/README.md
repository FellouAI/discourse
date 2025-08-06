# Discourse Report API Plugin

这个插件提供了一个API接口，允许外部系统自动创建报告topic。

## 功能特性

- 通过API创建topic
- 自动查找或创建用户
- 支持OIDC用户关联
- 支持标签和分类

## API 使用方法

### 端点
```
POST /api/reports
```

### 请求头
```
Content-Type: application/json
X-API-Key: your-secret-api-key
```

### 请求体
```json
{
  "id": "xxx",
  "title": "报告标题",
  "description": "报告描述",
  "report_url": "https://chat.fellou.ai/report/xxx",
  "tags": ["人物分析", "信息整合", "可视化报告"],
  "content_type": "html",
  "user_info": {
    "id": "xxx",
    "email": "user@example.com",
    "name": "用户名",
    "picture": "https://example.com/avatar.jpg",
    "authing_user_id": "authing_user_id",
    "given_name": "名",
    "phone_number": "13800138000"
  }
}
```

### 响应
```json
{
  "success": true,
  "topic_id": 123,
  "topic_url": "/t/topic-slug/123"
}
```

## 配置

在Discourse管理后台的插件设置中：

1. `report_api_enabled`: 启用/禁用API
2. `report_api_key`: 设置API密钥
3. `report_default_category`: 设置默认分类名称

## 安全注意事项

- 请修改默认的API密钥
- 建议在生产环境中使用HTTPS
- 考虑添加IP白名单限制 