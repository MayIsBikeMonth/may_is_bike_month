# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/landing", type: :request do
  describe "get root" do
    it "renders and does not create duplicate competitions" do
      expect(Competition.count).to eq 0
      get "/"
      expect(response.code).to eq "200"
      expect(Competition.count).to eq 1

      get "/"
      expect(response.code).to eq "200"
      expect(Competition.count).to eq 1
    end
  end

  describe "get root" do
    context "with current competition" do
      let!(:competition) { FactoryBot.create(:competition, start_date: Time.current.beginning_of_month.to_date) }

      it "uses the existing competition" do
        expect(Competition.count).to eq 1
        get "/"
        expect(response.code).to eq "200"
        expect(Competition.count).to eq 1
        expect(assigns(:competition).id).to eq competition.id
      end
    end
  end
end
