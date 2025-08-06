# 使用 Ubuntu 作为基础镜像
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    RUBY_VERSION=3.3.0 \
    BUNDLER_VERSION=2.6.4 \
    LANG=C.UTF-8

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    build-essential \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libyaml-dev \
    libffi-dev \
    libgdbm-dev \
    libncurses5-dev \
    libdb-dev \
    ca-certificates \
    autoconf \
    bison \
    libxml2-dev \
    libxslt1-dev \
    tzdata \
    imagemagick \
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js 20（兼容 pnpm 10+）
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    node -v && npm -v

# 安装 pnpm
RUN npm install -g pnpm && pnpm -v

# 安装 ruby-build 用于编译 Ruby
RUN git clone https://github.com/rbenv/ruby-build.git /tmp/ruby-build && \
    /tmp/ruby-build/install.sh && \
    rm -rf /tmp/ruby-build

# 编译安装 Ruby 3.3
RUN ruby-build "$RUBY_VERSION" /usr/local

# 设置 Ruby 可执行路径
RUN ln -sf /usr/local/bin/ruby /usr/bin/ruby && \
    ln -sf /usr/local/bin/gem /usr/bin/gem

# 安装 Bundler
RUN gem install bundler -v ${BUNDLER_VERSION} && \
    bundler -v

# 创建应用目录
WORKDIR /app

# 拷贝 Gemfile 和 Gemfile.lock
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.4.22
RUN bundle config set without 'development test'
RUN bundle install    

# 拷贝项目代码
COPY . .

# 编译 assets（可选）
RUN RAILS_ENV=production bundle exec rake assets:precompile

# 暴露端口
EXPOSE 3000

# 启动 puma
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]