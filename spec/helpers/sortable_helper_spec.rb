# frozen_string_literal: true

require "rails_helper"

RSpec.describe SortableHelper, type: :helper do
  before { controller.params = ActionController::Parameters.new(passed_params) }

  describe "sortable_params" do
    let(:params) { ActionController::Parameters.new(passed_params) }
    let(:passed_params) { {user_id: "something", per_page: 12, other: "Thing"} }
    it "returns as expected" do
      expect(sortable_params).to match passed_params.except(:other)
      # Verify indifferent access
      expect(sortable_params[:user_id]).to eq "something"
    end
    context "default sort and direction" do
      let(:default_direction) { "desc" }
      let(:default_column) { "created_at" }
      let(:passed_params) { {sort: "created_at", sort_direction: "desc", search_other: "example", user_id: "other", render_chart: "", period: ""} }
      it "returns with default sort and direction" do
        expect(sortable_params).to match({search_other: "example", user_id: "other"})
      end
    end
  end

  describe "sortable_search_params with default search_params" do
    context "no sortable_search_params" do
      let(:passed_params) { {party: "stuff"} }
      it "returns an empty hash" do
        expect(sortable_search_params.to_unsafe_h).to eq({})
      end
    end
    context "direction, sort" do
      let(:passed_params) { {direction: "asc", sort: "stolen", party: "long"} }
      let(:target) { {direction: "asc", sort: "stolen"} }
      it "returns an empty hash" do
        expect(sortable_search_params.to_unsafe_h).to eq(target.as_json)
        expect(sortable_search_params?).to be_falsey
      end
    end
    context "direction, sort, period: all " do
      let(:passed_params) { {direction: "asc", sort: "stolen", period: "all"} }
      let(:target) { {direction: "asc", sort: "stolen", period: "all"} }
      it "returns an empty hash" do
        expect(sortable_search_params?).to be_falsey
      end
    end
    context "direction, sort, period: week" do
      let(:passed_params) { {direction: "asc", sort: "stolen", period: "week"} }
      let(:target) { {direction: "asc", sort: "stolen", period: "week"} }
      it "returns an empty hash" do
        expect(sortable_search_params?).to be_truthy
        expect(sortable_search_params?(except: [:period])).to be_falsey
      end
    end
    context "direction, sort, search param, user_id" do
      let(:passed_params) { {direction: "asc", sort: "stolen", party: "long", search_stuff: "xxx", user_id: 21, query: "something"} }
      let(:target) { {direction: "asc", sort: "stolen", search_stuff: "xxx", user_id: 21, query: "something"} }
      it "returns an empty hash" do
        expect(sortable_search_params.to_unsafe_h).to eq(target.as_json)
        expect(sortable_search_params?).to be_truthy
        expect(sortable_search_params?(except: [:user_id])).to be_truthy
        expect(sortable_search_params?(except: [:search_stuff, :user_id, :query])).to be_falsey
      end
    end
  end
end
