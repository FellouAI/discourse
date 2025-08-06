# Discourse Report URL Plugin - 使用指南

## 功能概述

这个插件为Discourse添加了两个主要功能：

1. **话题创建时添加 report_url 参数** - 允许在创建话题时传递一个可访问的URL
2. **话题列表显示总点赞数** - 在话题列表中显示该话题下所有帖子的点赞总数

## API 使用示例

### 1. 创建话题时添加 report_url

**请求示例：**
```bash
curl -X POST "https://your-discourse.com/posts.json" \
  -H "Content-Type: application/json" \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: your_username" \
  -d '{
    "raw": "这是一个测试话题的内容",
    "title": "测试话题标题",
    "category": 1,
    "report_url": "https://example.com/report/123"
  }'
```

**响应示例：**
```json
{
  "post": {
    "id": 123,
    "topic_id": 456,
    "raw": "这是一个测试话题的内容",
    "cooked": "<p>这是一个测试话题的内容</p>"
  },
  "topic": {
    "id": 456,
    "title": "测试话题标题",
    "custom_fields": {
      "report_url": "https://example.com/report/123"
    }
  }
}
```

### 2. 获取话题列表（包含 report_url 和总点赞数）

**请求示例：**
```bash
# 最新话题列表
curl -X GET "https://your-discourse.com/latest.json" \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: your_username"

# 热门话题列表
curl -X GET "https://your-discourse.com/hot.json" \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: your_username"

# 分类话题列表
curl -X GET "https://your-discourse.com/c/1.json" \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: your_username"
```

**响应示例：**
```json
{
  "topic_list": {
    "topics": [
      {
        "id": 456,
        "title": "测试话题标题",
        "report_url": "https://example.com/report/123",
        "total_likes_count": 15,
        "posts_count": 5,
        "reply_count": 4,
        "created_at": "2024-01-01T10:00:00.000Z",
        "last_posted_at": "2024-01-02T15:30:00.000Z",
        "like_count": 8,
        "views": 120,
        "category_id": 1
      }
    ],
    "users": [...],
    "categories": [...]
  }
}
```

### 3. 获取话题详情（包含 report_url 和总点赞数）

**请求示例：**
```bash
curl -X GET "https://your-discourse.com/t/456.json" \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: your_username"
```

**响应示例：**
```json
{
  "topic": {
    "id": 456,
    "title": "测试话题标题",
    "report_url": "https://example.com/report/123",
    "total_likes_count": 15,
    "posts_count": 5,
    "reply_count": 4,
    "created_at": "2024-01-01T10:00:00.000Z",
    "last_posted_at": "2024-01-02T15:30:00.000Z"
  },
  "post_stream": {
    "posts": [...]
  }
}
```

### 4. 获取用户行为列表（包含 report_url）

**请求示例：**
```bash
curl -X GET "https://your-discourse.com/user_actions.json?username=user1&filter=4,5" \
  -H "Api-Key: YOUR_API_KEY" \
  -H "Api-Username: your_username"
```

**响应示例：**
```json
{
  "user_actions": [
    {
      "id": 123,
      "action_type": 4,
      "created_at": "2024-01-01T10:00:00.000Z",
      "report_url": "https://example.com/report/123",
      "total_likes_count": 15
    }
  ]
}
```

## 字段说明

### report_url
- **类型**: String
- **描述**: 话题关联的可访问URL
- **存储位置**: 话题的自定义字段中
- **可选**: 是，创建话题时可以不传递此参数
- **返回位置**: 所有话题相关的API接口

### total_likes_count
- **类型**: Integer
- **描述**: 该话题下所有帖子的点赞总数
- **计算方式**: 统计该话题下所有未删除帖子的点赞数量
- **实时性**: 实时计算，每次请求都会重新统计

## 支持的接口

插件会在以下接口中返回 `report_url` 和 `total_likes_count` 字段：

1. **话题列表接口**：
   - `/latest.json` - 最新话题
   - `/hot.json` - 热门话题
   - `/top.json` - 热门话题
   - `/c/[category_id].json` - 分类话题
   - `/tags/[tag].json` - 标签话题

2. **话题详情接口**：
   - `/t/[topic_id].json` - 话题详情

3. **用户行为接口**：
   - `/user_actions.json` - 用户行为列表

4. **搜索接口**：
   - `/search.json` - 搜索结果

## 技术实现说明

### UserAction 接口的特殊处理

由于 `UserAction.stream` 方法返回的是原始SQL查询结果而不是ActiveRecord对象，插件对用户行为接口进行了特殊处理：

```ruby
# 在 UserActionSerializer 中获取 report_url
add_to_serializer(:user_action, :report_url) do
  if object.respond_to?(:topic_id) && object.topic_id
    topic = Topic.find_by(id: object.topic_id)
    topic&.custom_fields&.[](DiscourseReportUrl::REPORT_URL_FIELD)
  end
end

# 在 UserActionSerializer 中获取 total_likes_count
add_to_serializer(:user_action, :total_likes_count) do
  if object.respond_to?(:topic_id) && object.topic_id
    topic = Topic.find_by(id: object.topic_id)
    DiscourseReportUrl.calculate_topic_total_likes(topic)
  else
    0
  end
end
```

这确保了即使在用户行为接口中也能正确返回 `report_url` 和 `total_likes_count` 字段。

## 注意事项

1. **权限控制**: 只有有权限创建话题的用户才能使用 report_url 参数
2. **URL 验证**: 插件不会验证 report_url 的格式，请确保传递有效的URL
3. **性能考虑**: total_likes_count 是实时计算的，对于大量话题的列表可能会有性能影响
4. **数据一致性**: 点赞数的计算会排除已删除的帖子和已删除的点赞记录
5. **UserAction 性能**: 在用户行为接口中，插件会额外查询话题信息，可能影响性能

## 错误处理

如果传递了无效的 report_url 参数，API 会返回 400 错误：

```json
{
  "errors": ["Invalid report_url parameter"]
}
```

## 插件配置

在Discourse管理面板的"设置" -> "插件"中，可以找到 "report_url_enabled" 选项来启用或禁用插件功能。 