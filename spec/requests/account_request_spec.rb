# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/account", type: :request do
  let(:base_path) { "/account" }

  it "redirects" do
    get "#{base_path}/edit"
    expect(response).to redirect_to root_url
  end

  context "logged in" do
    include_context :logged_in_as_user

    describe "edit" do
      it "renders with system theme selected by default" do
        get "#{base_path}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("accounts/edit")
        expect(response.body).to include('data-theme-current-value="system"')
      end
    end
  end
end
