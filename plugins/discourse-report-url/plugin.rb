# frozen_string_literal: true

# name: discourse-report-url
# about: Adds report_url field to topics and total likes count to topic lists
# version: 0.1
# authors: Your Name
# url: https://github.com/your-repo/discourse-report-url

enabled_site_setting :report_url_enabled

module ::DiscourseReportUrl
  PLUGIN_NAME = "discourse-report-url"
  REPORT_URL_FIELD = "report_url"
end

# Helper method to calculate total likes for a topic
def DiscourseReportUrl.calculate_topic_total_likes(topic)
  return 0 unless topic

  PostAction
    .joins(:post)
    .where(
      posts: { topic_id: topic.id, deleted_at: nil },
      post_action_type_id: PostActionType.types[:like],
      deleted_at: nil
    )
    .count
end

after_initialize do
  # Add permitted parameter for report_url
  add_permitted_post_create_param(:report_url)

  # Listen for topic creation to save report_url
  DiscourseEvent.on(:topic_created) do |topic, opts, user|
    if opts[:report_url].present?
      topic.custom_fields[DiscourseReportUrl::REPORT_URL_FIELD] = opts[:report_url]
      topic.save_custom_fields
    end
  end

  # Add report_url to topic list item serializer (for topic lists)
  add_to_serializer(:topic_list_item, :report_url) do
    object.custom_fields[DiscourseReportUrl::REPORT_URL_FIELD]
  end

  # Add report_url to topic view serializer (for topic details)
  add_to_serializer(:topic_view, :report_url) do
    object.topic.custom_fields[DiscourseReportUrl::REPORT_URL_FIELD]
  end

  # Add report_url to user action serializer (for user actions)
  add_to_serializer(:user_action, :report_url) do
    # UserAction.stream returns raw SQL results, so we need to fetch topic separately
    if object.respond_to?(:topic_id) && object.topic_id
      topic = Topic.find_by(id: object.topic_id)
      topic&.custom_fields&.[](DiscourseReportUrl::REPORT_URL_FIELD)
    end
  end

  # Add total likes count to topic list item serializer
  add_to_serializer(:topic_list_item, :total_likes_count) do
    DiscourseReportUrl.calculate_topic_total_likes(object)
  end

  # Add total likes count to topic view serializer
  add_to_serializer(:topic_view, :total_likes_count) do
    DiscourseReportUrl.calculate_topic_total_likes(object.topic)
  end

  # Add total likes count to user action serializer
  add_to_serializer(:user_action, :total_likes_count) do
    # UserAction.stream returns raw SQL results, so we need to fetch topic separately
    if object.respond_to?(:topic_id) && object.topic_id
      topic = Topic.find_by(id: object.topic_id)
      DiscourseReportUrl.calculate_topic_total_likes(topic)
    else
      0
    end
  end

  # Add topic content to topic list item serializer
  add_to_serializer(:topic_list_item, :topic_content) do
    first_post = object.first_post
    first_post&.raw || ""
  end

  # Add topic content to topic view serializer
  add_to_serializer(:topic_view, :topic_content) do
    first_post = object.topic.first_post
    first_post&.raw || ""
  end

  # Add topic content to user action serializer
  add_to_serializer(:user_action, :topic_content) do
    if object.respond_to?(:topic_id) && object.topic_id
      topic = Topic.find_by(id: object.topic_id)
      first_post = topic&.first_post
      first_post&.raw || ""
    else
      ""
    end
  end

  # Preload custom fields for better performance
  add_preloaded_topic_list_custom_field(DiscourseReportUrl::REPORT_URL_FIELD)
end
