# frozen_string_literal: true

require "rails_helper"

describe DiscourseReportUrl do
  let(:user) { Fabricate(:user) }
  let(:category) { Fabricate(:category) }

  before do
    SiteSetting.report_url_enabled = true
  end

  describe "topic creation with report_url" do
    it "saves report_url to topic custom fields" do
      post_creator = PostCreator.new(
        user,
        title: "Test Topic",
        raw: "This is a test topic",
        category: category.id,
        report_url: "https://example.com/report"
      )

      post = post_creator.create
      expect(post_creator.errors).to be_empty
      expect(post.topic.custom_fields["report_url"]).to eq("https://example.com/report")
    end

    it "does not save report_url when not provided" do
      post_creator = PostCreator.new(
        user,
        title: "Test Topic",
        raw: "This is a test topic",
        category: category.id
      )

      post = post_creator.create
      expect(post_creator.errors).to be_empty
      expect(post.topic.custom_fields["report_url"]).to be_nil
    end
  end

  describe "serializer extensions" do
    let(:topic) { Fabricate(:topic, category: category) }
    let(:post1) { Fabricate(:post, topic: topic) }
    let(:post2) { Fabricate(:post, topic: topic) }
    let(:user1) { Fabricate(:user) }
    let(:user2) { Fabricate(:user) }

    before do
      topic.custom_fields["report_url"] = "https://example.com/report"
      topic.save_custom_fields
    end

    it "includes report_url in topic list serializer" do
      serializer = TopicListItemSerializer.new(topic, scope: Guardian.new(user))
      json = serializer.as_json

      expect(json[:topic_list_item][:report_url]).to eq("https://example.com/report")
    end

    it "includes report_url in topic view serializer" do
      topic_view = TopicView.new(topic.id, user)
      serializer = TopicViewSerializer.new(topic_view, scope: Guardian.new(user))
      json = serializer.as_json

      expect(json[:topic_view][:report_url]).to eq("https://example.com/report")
    end

    it "calculates total likes count correctly" do
      # Create likes on posts
      PostAction.create!(
        user: user1,
        post: post1,
        post_action_type_id: PostActionType.types[:like]
      )

      PostAction.create!(
        user: user2,
        post: post2,
        post_action_type_id: PostActionType.types[:like]
      )

      serializer = TopicListItemSerializer.new(topic, scope: Guardian.new(user))
      json = serializer.as_json

      expect(json[:topic_list_item][:total_likes_count]).to eq(2)
    end

    it "returns 0 for total likes when no likes exist" do
      serializer = TopicListItemSerializer.new(topic, scope: Guardian.new(user))
      json = serializer.as_json

      expect(json[:topic_list_item][:total_likes_count]).to eq(0)
    end

    it "includes report_url in user action serializer" do
      # Create a user action through the proper channel
      UserAction.log_action!(
        action_type: UserAction::NEW_TOPIC,
        user_id: user.id,
        acting_user_id: user.id,
        target_topic_id: topic.id,
        target_post_id: -1
      )

      # Get the user action through the stream method
      user_action = UserAction.stream(user_id: user.id, guardian: Guardian.new(user)).first
      serializer = UserActionSerializer.new(user_action, scope: Guardian.new(user))
      json = serializer.as_json

      expect(json[:user_action][:report_url]).to eq("https://example.com/report")
    end

    it "includes total_likes_count in user action serializer" do
      # Create likes on posts
      PostAction.create!(
        user: user1,
        post: post1,
        post_action_type_id: PostActionType.types[:like]
      )

      # Create a user action through the proper channel
      UserAction.log_action!(
        action_type: UserAction::NEW_TOPIC,
        user_id: user.id,
        acting_user_id: user.id,
        target_topic_id: topic.id,
        target_post_id: -1
      )

      # Get the user action through the stream method
      user_action = UserAction.stream(user_id: user.id, guardian: Guardian.new(user)).first
      serializer = UserActionSerializer.new(user_action, scope: Guardian.new(user))
      json = serializer.as_json

      expect(json[:user_action][:total_likes_count]).to eq(1)
    end
  end

  describe "API endpoint" do
    before do
      sign_in(user)
    end

    it "accepts report_url parameter in posts API" do
      post "/posts.json", params: {
        raw: "This is a test post",
        title: "Test Topic",
        category: category.id,
        report_url: "https://example.com/report"
      }

      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json["topic"]["custom_fields"]["report_url"]).to eq("https://example.com/report")
    end
  end
end 