require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "number_display" do
    let(:target) { "<span>1</span>" }
    it "renders" do
      expect(number_display(1)).to eq target
    end
    context "with round_to" do
      let(:target) { "<span>1.0</span>" }
      it "renders" do
        expect(number_display(1, round_to: 1)).to eq target
      end
    end
  end

  describe "competition_activity_display" do
    let(:competition_activity) { FactoryBot.create(:competition_activity) }
    let(:target) { "<span>Cool ride</span>" }
    it "renders" do
      expect(competition_activity_display(competition_activity)).to eq target
    end
    context "with manual_entry entered_after_competition_ended" do
      before do
        allow(competition_activity).to receive(:manual_entry?).and_return(true)
        allow(competition_activity).to receive(:entered_after_competition_ended?).and_return(true)
      end
      let(:target) { '<span>Cool ride <strong title="ignored, manual entry after competition ended">?</strong></span>' }
      it "renders" do
        expect(competition_activity_display(competition_activity)).to eq target
      end
    end
  end

  describe "active_link" do
    context "match_controller" do
      let(:request) { double("request", url: root_path) }
      before { allow(helper).to receive(:request).and_return(request) }
      it "returns the link active with match_controller if on the controller" do
        expect(active_link("Home", root_path, class: "home_header", id: "something", match_controller: true)).to eq '<a class="home_header active" id="something" href="' + root_path + '">Home</a>'
      end
    end
  end

  describe "page_title" do
    before do
      allow(view).to receive(:controller_name) { controller_name }
      allow(view).to receive(:action_name) { action_name }
      # this method is defined in application controller, stub it
      def helper.controller_namespace
      end
      allow(view).to receive(:controller_namespace) { controller_namespace }
    end
    let(:controller_namespace) { nil }

    context "home controller" do
      let(:controller_name) { "home" }
      let(:action_name) { "index" }
      it "returns default" do
        expect(helper.page_title).to eq "HeartHeartBeat Home" # Though this is overridden to omit "home"
      end
    end

    describe "admin" do
      let(:controller_name) { "users" }
      let(:controller_namespace) { "admin" }
      let(:action_name) { "index" }
      it "uses admin" do
        expect(helper.page_title).to eq "🧰 Users"
      end
      context "assigned controller_display_name" do
        let(:controller_name) { "staffed_computers" }
        it "uses the assigned value" do
          @controller_display_name = "Password Management"
          expect(helper.page_title).to eq "🧰 Password Management"
        end
      end
    end

    context "page_title assigned" do
      let(:controller_name) { "landing" }
      let(:action_name) { "index" }
      it "uses the ivar" do
        @page_title = "title stuff"
        expect(helper.page_title).to eq "title stuff"
      end
    end
  end
end
