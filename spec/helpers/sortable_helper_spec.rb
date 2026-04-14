# frozen_string_literal: true

require "rails_helper"

RSpec.describe Binxtils::SortableHelper, type: :helper do
  before { controller.params = ActionController::Parameters.new(passed_params) }

  describe "sortable_search_params" do
    context "no sortable_search_params" do
      let(:passed_params) { {party: "stuff"} }
      it "returns an empty hash" do
        expect(sortable_search_params.to_unsafe_h).to eq({})
      end
    end

    context "direction, sort" do
      let(:passed_params) { {direction: "asc", sort: "stolen", party: "long"} }
      let(:target) { {direction: "asc", sort: "stolen"} }
      it "returns target hash" do
        expect(sortable_search_params.to_unsafe_h).to eq(target.as_json)
      end
    end

    context "direction, sort, search param" do
      let(:time) { Time.current.to_i }
      let(:passed_params) { {direction: "asc", sort: "stolen", party: "long", search_stuff: "xxx", user_id: 21, start_time: time, end_time: time, period: "custom"} }
      let(:target) { {direction: "asc", sort: "stolen", search_stuff: "xxx", user_id: 21, start_time: time, end_time: time, period: "custom"} }
      it "returns target hash" do
        expect(sortable_search_params.to_unsafe_h).to eq(target.as_json)
      end
    end

    context "direction, sort, period: all" do
      let(:passed_params) { {direction: "asc", sort: "stolen", period: "all"} }
      it "is falsey" do
        expect(sortable_search_params?).to be_falsey
      end
    end

    context "direction, sort, period: week" do
      let(:passed_params) { {direction: "asc", sort: "stolen", period: "week"} }
      it "is truthy" do
        expect(sortable_search_params?).to be_truthy
      end
    end
  end
end
