# frozen_string_literal: true

shared_context :logged_in_as_user do
  let(:user) { FactoryBot.create(:user) }
  before { sign_in user }
end

shared_context :logged_in_as_superuser do
  let(:user) { FactoryBot.create(:user_admin) }
  before { sign_in user }
end

# Request spec helpers that are included in all request specs via Rspec.configure (rails_helper)
module RequestSpecHelpers
  def json_headers
    {"CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json"}
  end

  def json_result
    r = JSON.parse(response.body)
    r.is_a?(Hash) ? r.with_indifferent_access : r
  end
end
