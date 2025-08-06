# Discourse Report URL Plugin

这个插件为Discourse添加了两个主要功能：

## 功能

### 1. 话题创建时添加 report_url 参数

- 在创建新话题时，可以通过 `/posts` 接口传递 `report_url` 参数
- 该参数会被保存到话题的自定义字段中
- 在话题列表和话题详情中都会返回这个字段

### 2. 话题列表显示总点赞数

- 在话题列表中为每个话题添加 `total_likes_count` 字段
- 该字段显示该话题下所有帖子的点赞总数
- 在话题详情页面也会显示总点赞数

## 使用方法

### 创建话题时添加 report_url

```bash
POST /posts.json
{
  "raw": "话题内容",
  "title": "话题标题",
  "report_url": "https://example.com/report"
}
```

### API 响应示例

话题列表响应：
```json
{
  "topics": [
    {
      "id": 1,
      "title": "话题标题",
      "report_url": "https://example.com/report",
      "total_likes_count": 15
    }
  ]
}
```

话题详情响应：
```json
{
  "topic": {
    "id": 1,
    "title": "话题标题",
    "report_url": "https://example.com/report",
    "total_likes_count": 15
  }
}
```

## 安装

1. 将插件文件夹复制到 `plugins/` 目录
2. 重启Discourse服务
3. 在管理面板中启用插件

## 配置

在站点设置中可以启用/禁用插件功能。 