# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportApiController, type: :controller do
  before do
    SiteSetting.report_api_enabled = true
    SiteSetting.report_api_key = 'test-api-key'
  end

  describe 'POST /api/reports' do
    let(:valid_params) do
      {
        id: 'test-report-123',
        title: '测试报告',
        description: '这是一个测试报告',
        report_url: 'https://chat.fellou.ai/report/test',
        tags: ['测试', '报告'],
        content_type: 'html',
        user_info: {
          id: 'user-123',
          email: 'test@example.com',
          name: '测试用户',
          picture: 'https://example.com/avatar.jpg',
          authing_user_id: 'authing-123',
          given_name: '测试',
          phone_number: '13800138000'
        }
      }
    end

    context 'with valid API key' do
      before do
        request.headers['X-API-Key'] = 'test-api-key'
      end

      it 'creates a new topic successfully' do
        post :create, params: valid_params
        
        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['topic_id']).to be_present
      end

      it 'creates user if not exists' do
        expect {
          post :create, params: valid_params
        }.to change { User.count }.by(1)
      end
    end

    context 'with invalid API key' do
      before do
        request.headers['X-API-Key'] = 'wrong-key'
      end

      it 'returns unauthorized error' do
        post :create, params: valid_params
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid API key')
      end
    end

    context 'with missing parameters' do
      before do
        request.headers['X-API-Key'] = 'test-api-key'
      end

      it 'returns bad request error' do
        post :create, params: { title: 'test' }
        
        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Missing required parameters')
      end
    end
  end
end 