#!/usr/bin/env ruby

# 简单的插件功能测试脚本
# 这个脚本可以用来验证插件的基本功能

puts "Discourse Report URL Plugin Test"
puts "================================"

# 检查插件文件是否存在
required_files = [
  "plugin.rb",
  "config/settings.yml",
  "README.md",
  "plugin.yml"
]

puts "\n检查插件文件结构:"
required_files.each do |file|
  if File.exist?(file)
    puts "✓ #{file}"
  else
    puts "✗ #{file} (缺失)"
  end
end

# 检查插件配置
puts "\n检查插件配置:"
if File.exist?("config/settings.yml")
  settings_content = File.read("config/settings.yml")
  if settings_content.include?("report_url_enabled")
    puts "✓ 站点设置配置正确"
  else
    puts "✗ 站点设置配置缺失"
  end
else
  puts "✗ 站点设置文件缺失"
end

# 检查插件主文件
puts "\n检查插件主文件:"
if File.exist?("plugin.rb")
  plugin_content = File.read("plugin.rb")
  
  checks = [
    { name: "插件名称定义", pattern: /DiscourseReportUrl/ },
    { name: "添加允许的参数", pattern: /add_permitted_post_create_param/ },
    { name: "话题创建事件监听", pattern: /DiscourseEvent\.on\(:topic_created\)/ },
    { name: "序列化器扩展", pattern: /add_to_serializer/ },
    { name: "自定义字段预加载", pattern: /add_preloaded_topic_list_custom_field/ }
  ]
  
  checks.each do |check|
    if plugin_content.match(check[:pattern])
      puts "✓ #{check[:name]}"
    else
      puts "✗ #{check[:name]}"
    end
  end
else
  puts "✗ 插件主文件缺失"
end

puts "\n插件测试完成！"
puts "要启用插件，请重启Discourse服务并在管理面板中启用插件。" 