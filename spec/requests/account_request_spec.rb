# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/account", type: :request do
  let(:base_path) { "/account" }

  it "redirects" do
    patch base_path, params: {user: {theme: "theme_dark"}}, as: :json
    expect(response).to redirect_to root_url
  end

  context "logged in" do
    include_context :logged_in_as_user

    describe "update" do
      it "updates theme and unit" do
        expect(user.theme).to eq "theme_system"
        expect(user.unit).to eq "imperial"
        patch base_path, params: {user: {theme: "theme_dark"}}, as: :json
        expect(response.code).to eq "200"
        expect(user.reload.theme).to eq "theme_dark"
        expect(user.unit).to eq "imperial"

        patch base_path, params: {user: {unit: "metric"}}, as: :json
        expect(response.code).to eq "200"
        expect(user.reload.unit).to eq "metric"
        expect(user.theme).to eq "theme_dark"
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

      context "imperial" do
        let(:user) { FactoryBot.create(:user, unit: :metric) }

        it "updates unit to imperial" do
          expect(user.unit).to eq "metric"
          patch base_path, params: {user: {unit: "imperial"}}, as: :json
          expect(response.code).to eq "200"
          expect(user.reload.unit).to eq "imperial"
        end
      end
    end
  end
end
