# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/account", type: :request do
  let(:base_url) { "/account" }

  it "redirects" do
    get "#{base_url}/edit"
    expect(response).to redirect_to root_url
  end

  context "logged in" do
    include_context :logged_in_as_user

    describe "edit" do
      it "renders" do
        get "#{base_url}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("accounts/edit")
      end
    end
  end
end
