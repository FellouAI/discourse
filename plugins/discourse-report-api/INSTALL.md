# 安装和配置说明

## 1. 安装插件

将插件文件夹复制到你的Discourse项目的 `plugins/` 目录下：

```bash
cp -r discourse-report-api /path/to/your/discourse/plugins/
```

## 2. 启用插件

在Discourse管理后台：

1. 进入 **管理** → **插件**
2. 找到 **Discourse Report API** 插件
3. 点击 **启用**

## 3. 配置设置

在Discourse管理后台：

1. 进入 **管理** → **设置** → **插件**
2. 找到 **Report API** 相关设置
3. 配置以下设置：
   - `report_api_enabled`: 设置为 `true`
   - `report_api_key`: 设置你的API密钥（建议使用强密码）
   - `report_default_category`: 设置默认分类名称（如：报告）

## 4. 重启Discourse

```bash
# 如果使用Docker
./launcher rebuild app

# 或者重启Rails服务器
bundle exec rails server
```

## 5. 测试API

使用提供的测试脚本：

```bash
cd plugins/discourse-report-api
ruby test_api.rb
```

记得修改脚本中的 `base_url` 和 `api_key` 参数。

## 6. 使用curl测试

```bash
curl -X POST http://your-discourse-url/api/reports \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-secret-api-key" \
  -d '{
    "id": "test-123",
    "title": "测试报告",
    "description": "这是一个测试报告",
    "report_url": "https://chat.fellou.ai/report/test",
    "tags": ["测试", "报告"],
    "content_type": "html",
    "user_info": {
      "id": "user-123",
      "email": "test@example.com",
      "name": "测试用户",
      "picture": "https://example.com/avatar.jpg",
      "authing_user_id": "authing-123",
      "given_name": "测试",
      "phone_number": "13800138000"
    }
  }'
```

## 7. 安全建议

1. **修改API密钥**: 默认密钥不安全，请立即修改
2. **使用HTTPS**: 在生产环境中使用HTTPS
3. **IP白名单**: 考虑限制允许访问API的IP地址
4. **频率限制**: 考虑添加请求频率限制
5. **日志监控**: 监控API使用情况

## 8. 故障排除

### 常见问题

1. **404错误**: 检查插件是否正确启用
2. **401错误**: 检查API密钥是否正确
3. **500错误**: 检查Rails日志获取详细错误信息

### 查看日志

```bash
# 查看Rails日志
tail -f log/development.log

# 如果使用Docker
./launcher logs app
``` 