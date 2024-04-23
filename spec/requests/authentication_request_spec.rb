# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "sign in" do
    it "renders sign_in page" do
      get "/users/sign_in"
      expect(response.code).to eq "404"
    end
  end

  describe "sign up" do
    it "renders sign_up page" do
      get "/users/sign_up"
      expect(response.code).to eq "404"
    end
  end
end