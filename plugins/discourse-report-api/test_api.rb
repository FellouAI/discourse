#!/usr/bin/env ruby

require 'net/http'
require 'json'
require 'uri'

# 测试API的简单脚本
class ReportApiTester
  def initialize(base_url, api_key)
    @base_url = base_url
    @api_key = api_key
  end

  def test_create_report
    uri = URI("#{@base_url}/api/reports")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request['X-API-Key'] = @api_key

    # 测试数据
    test_data = {
      id: "test-report-#{Time.now.to_i}",
      title: "测试报告 #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}",
      description: "这是一个通过API创建的测试报告，用于验证功能是否正常。",
      report_url: "https://chat.fellou.ai/report/test-#{Time.now.to_i}",
      tags: ["测试", "API", "报告"],
      content_type: "html",
      user_info: {
        id: "test-user-#{Time.now.to_i}",
        email: "test#{Time.now.to_i}@example.com",
        name: "测试用户",
        picture: "https://example.com/avatar.jpg",
        authing_user_id: "authing-test-#{Time.now.to_i}",
        given_name: "测试",
        phone_number: "13800138000"
      }
    }

    request.body = test_data.to_json

    puts "发送请求到: #{uri}"
    puts "请求数据: #{JSON.pretty_generate(test_data)}"
    puts "=" * 50

    begin
      response = http.request(request)
      
      puts "响应状态: #{response.code}"
      puts "响应头: #{response.to_hash}"
      puts "响应体: #{response.body}"
      
      if response.code == '200'
        result = JSON.parse(response.body)
        puts "✅ 成功创建报告!"
        puts "Topic ID: #{result['topic_id']}"
        puts "Topic URL: #{result['topic_url']}"
      else
        puts "❌ 创建失败"
      end
      
    rescue => e
      puts "❌ 请求失败: #{e.message}"
    end
  end
end

# 使用示例
if __FILE__ == $0
  # 修改这些参数为你的实际配置
  base_url = "http://localhost:3000"  # 你的Discourse地址
  api_key = "your-secret-api-key"     # 你的API密钥
  
  tester = ReportApiTester.new(base_url, api_key)
  tester.test_create_report
end 