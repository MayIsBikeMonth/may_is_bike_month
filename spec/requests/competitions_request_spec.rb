# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/competitions", type: :request do
  describe "get root" do
    let!(:competition) { FactoryBot.create(:competition) }
    it "renders" do
      get "/competitions/#{competition.slug}"
      expect(response.code).to eq "200"
      expect(response).to render_template("show")
    end
  end
end
