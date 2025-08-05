# 使用已有的依赖镜像
FROM discourse-deps:v0.2

# 复制Gemfile和Gemfile.lock
COPY Gemfile Gemfile.lock ./

# 安装Ruby gems
RUN bundle install --jobs 4 --retry 3

# 复制package.json和package-lock.json
COPY package*.json ./

# 安装Node.js依赖
RUN npm ci --only=production

# 复制应用代码
COPY . .

# 创建启动脚本
RUN echo '#!/bin/bash' > /app/docker-entrypoint.sh && \
    echo 'set -e' >> /app/docker-entrypoint.sh && \
    echo '' >> /app/docker-entrypoint.sh && \
    echo '# 预编译资源' >> /app/docker-entrypoint.sh && \
    echo 'echo "Precompiling assets..."' >> /app/docker-entrypoint.sh && \
    echo 'bundle exec rake assets:precompile RAILS_ENV=production' >> /app/docker-entrypoint.sh && \
    echo '' >> /app/docker-entrypoint.sh && \
    echo '# 启动应用' >> /app/docker-entrypoint.sh && \
    echo 'echo "Starting Discourse..."' >> /app/docker-entrypoint.sh && \
    echo 'exec bundle exec unicorn -p 3000 -c config/unicorn.conf.rb' >> /app/docker-entrypoint.sh

RUN chmod +x /app/docker-entrypoint.sh

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# 设置启动命令
ENTRYPOINT ["/app/docker-entrypoint.sh"]
