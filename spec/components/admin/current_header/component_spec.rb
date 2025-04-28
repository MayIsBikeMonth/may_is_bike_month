# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::CurrentHeader::Component, type: :component do
  let(:default_options) do
    {
      viewing: "competition_users",
      include_competition_select: true,
      competition_subject: nil,
      searchable_competitions: Competition.order(start_date: :desc),
      render_period: false,
      s_params: {}
    }
  end
  let(:options) { default_options }
  let(:instance) { described_class.new(**options) }
  let(:component) { render_inline(instance) }

  it "renders" do
    expect(component).to be_present

    expect(instance.render?).to be_truthy
  end

  context "with include_competition_select: false" do
    let(:options) { default_options.except(:include_competition_select) }

    it "does not render" do
      expect(component).to be_present

      expect(instance.render?).to be_falsey
    end
  end
end
