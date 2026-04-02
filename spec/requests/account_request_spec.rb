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
        expect(response.body).to include('data-theme-current-value="theme_system"')
      end
    end

    describe "update" do
      it "updates theme" do
        expect(user.theme).to eq "theme_system"
        patch base_path, params: {user: {theme: "theme_dark"}}, as: :json
        expect(response.code).to eq "200"
        expect(user.reload.theme).to eq "theme_dark"
      end

      context "theme_light" do
        let(:user) { FactoryBot.create(:user, theme: :theme_dark) }

        it "updates theme" do
          expect(user.theme).to eq "theme_dark"
          patch base_path, params: {user: {theme: "theme_light"}}, as: :json
          expect(response.code).to eq "200"
          expect(user.reload.theme).to eq "theme_light"
        end
      end
    end
  end
end
