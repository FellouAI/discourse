#!/bin/bash
set -e

echo "🚀 开始构建Discourse Docker镜像..."

# 构建应用镜像（使用已有的依赖镜像）
echo "🏗️  构建应用镜像..."
docker build -t discourse:latest .

# 启动服务
echo "🚀 启动Discourse服务..."
docker-compose up -d

echo "✅ 构建完成！"
echo "📱 Discourse将在 http://localhost:3000 启动"
echo "🗄️  PostgreSQL在 localhost:5432"
echo "🔴  Redis在 localhost:6379"
echo ""
echo "查看日志: docker-compose logs -f discourse"
echo "停止服务: docker-compose down" 