# frozen_string_literal: true

# name: discourse-report-api
# about: API for creating reports/topics from external systems
# version: 1.0
# authors: Your Name
# url: https://github.com/your-repo/discourse-report-api

enabled_site_setting :report_api_enabled

# 注册路由
after_initialize do
  require_relative "lib/report_api_controller"
  
  # 添加API路由
  Discourse::Application.routes.append do
    post "/api/reports" => "report_api#create"
  end
end 