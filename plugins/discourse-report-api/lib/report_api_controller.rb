# frozen_string_literal: true

class ReportApiController < ApplicationController
  skip_before_action :check_xhr
  skip_before_action :redirect_to_login_if_required
  skip_before_action :verify_authenticity_token
  
  def create
    # API密钥验证
    api_key = request.headers['X-API-Key']
    unless valid_api_key?(api_key)
      return render json: { error: 'Invalid API key' }, status: 401
    end
    
    # 验证必需参数
    unless valid_params?
      return render json: { error: 'Missing required parameters' }, status: 400
    end
    
    begin
      # 处理用户信息
      user_result = process_user_info(params[:user_info])
      
      if user_result[:error]
        return render json: { error: user_result[:error] }, status: 400
      end
      
      user = user_result[:user]
      
      # 创建topic
      topic = create_topic(user)
      
      render json: {
        success: true,
        topic_id: topic.id,
        topic_url: topic.url,
        user_id: user.id,
        username: user.username
      }
      
    rescue => e
      Rails.logger.error "Report API Error: #{e.message}"
      
      # 提取Validation failed:后面的错误信息
      if e.message.include?('Validation failed:')
        error_message = e.message.split('Validation failed:').last.strip
      else
        error_message = e.message
      end
      
      render json: { error: error_message }, status: 400
    end
  end
  
  private
  
  def valid_api_key?(api_key)
    expected_key = SiteSetting.report_api_key
    api_key == expected_key
  end
  
  def valid_params?
    params[:id].present? && 
    params[:title].present? && 
    params[:description].present? &&
    params[:user_info].present?
  end
  
  def process_user_info(user_info)
    # 检查是否有authing_user_id，如果有就是OIDC用户
    if user_info[:authing_user_id].blank?
      return { error: 'user not registered' }
    end
    
    # 2.1. 根据email查看当前用户是否存在
    user = find_user_by_email(user_info[:email])
    
    if user
      # 用户存在，确保OIDC关联正确
      ensure_oidc_association(user, user_info)
      { user: user }
    else
      # 用户不存在，直接创建OIDC用户
      user = create_oidc_user(user_info)
      { user: user }
    end
  end
  
  def find_user_by_email(email)
    return nil if email.blank?
    
    # 通过user_emails表查找用户
    user_email = UserEmail.find_by(email: email)
    user_email&.user
  end
  
  def is_oidc_user?(user_info)
    # 2.2. 检查用户是否为OIDC用户（空方法，后续实现）
    # 目前简单检查是否有authing_user_id
    user_info[:authing_user_id].present?
  end
  
  def ensure_oidc_association(user, user_info)
    # 确保用户与OIDC账户关联
    existing_association = UserAssociatedAccount.find_by(
      user: user,
      provider_name: 'oidc',
      provider_uid: user_info[:authing_user_id]
    )
    
    unless existing_association
      UserAssociatedAccount.create!(
        user: user,
        provider_name: 'oidc',
        provider_uid: user_info[:authing_user_id],
        info: {
          name: user_info[:name],
          image: user_info[:picture]
        }
      )
    end
  end
  
  def create_oidc_user(user_info)
    # 使用参数中的username，如果没有则从邮箱生成
    base_username = user_info[:username] || generate_username(user_info[:email])
    
    # 确保用户名不为空且唯一
    if base_username.blank?
      base_username = "user_#{SecureRandom.hex(4)}"
    end
    
    # 确保用户名唯一
    username = base_username
    counter = 1
    while User.exists?(username: username)
      username = "#{base_username}#{counter}"
      counter += 1
    end
    
    # 创建用户
    user = User.new(
      username: username,
      name: user_info[:name] || user_info[:given_name] || "用户",
      active: true,
      approved: true,
      trust_level: 1  # 设置信任等级1+
    )
    
    # 设置随机密码
    user.password = SecureRandom.hex(16)
    
    # 设置邮箱（Discourse要求必须有主邮箱）
    if user_info[:email].present?
      # 检查邮箱是否已被使用
      existing_user = UserEmail.find_by(email: user_info[:email])&.user
      if existing_user
        # 如果邮箱已被使用，返回现有用户
        return existing_user
      else
        user.email = user_info[:email]
      end
    else
      # 如果没有邮箱，创建一个临时邮箱
      user.email = "temp_#{SecureRandom.hex(8)}@example.com"
    end
    
 
    
    if user.save
      
      # 如果使用了临时邮箱，创建真实的邮箱关联
      if user_info[:email].present?
        UserEmail.create!(
          user_id: user.id,
          email: user_info[:email],
          primary: true
        )
      end
      
      # 关联OIDC账户
      UserAssociatedAccount.create!(
        user: user,
        provider_name: 'oidc',
        provider_uid: user_info[:authing_user_id],
        info: {
          name: user_info[:name],
          image: user_info[:picture]
        }
      )
    end
    
    user
  end
  
  def generate_username(email)
    # 从邮箱中提取用户名（@符号前的部分）
    base_username = email.to_s.split('@').first.gsub(/[^a-zA-Z0-9]/, '').downcase
    
    # 确保用户名不为空
    if base_username.blank?
      base_username = "user"
    end
    
    username = base_username
    
    counter = 1
    while User.exists?(username: username)
      username = "#{base_username}#{counter}"
      counter += 1
    end
    
    username
  end
  
  def create_topic(user)
    # 获取可用分类
    category = Category.where(read_restricted: false)
                       .where.not(name: ['General', 'Uncategorized', 'Meta'])
                       .first || Category.first
    
    # 确保分类存在
    category_id = category&.id || 1
    
    # 处理标签
    tag_names = params[:tags] || []
    tags = tag_names.map do |tag_name|
      Tag.find_or_create_by(name: tag_name)
    end
    
    puts ">>>>>>>>>>>user: " + user.inspect
    # 确保用户已创建并获取用户ID
    user_id = user.id
    
    # 创建topic
    topic = Topic.create!(
      title: params[:title],
      user: user,
      category_id: category_id,
      tags: tags,
      last_post_user_id: -1
    )
    
    # 如果有report_url，保存到topic的custom_fields中
    if params[:report_url].present?
      topic.custom_fields['report_url'] = params[:report_url]
      topic.save_custom_fields
    end
    
    # 创建首贴
    post_content = generate_post_content
    post = Post.create!(
      topic: topic,
      user: user,
      raw: post_content,
      post_type: Post.types[:regular]
    )
    
    # Discourse会自动设置first_post_id，不需要手动更新
    
    topic
  end
  
  def generate_post_content
    content = []
    content << params[:description]
    
    if params[:content_type].present?
      content << "\n\n**内容类型：** #{params[:content_type]}"
    end
    
    content.join("\n")
  end
end 