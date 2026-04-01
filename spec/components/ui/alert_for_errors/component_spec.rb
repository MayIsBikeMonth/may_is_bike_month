# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::AlertForErrors::Component, type: :component do
  let(:instance) { described_class.new(**options) }
  let(:component) { render_inline(instance) }
  let(:options) { {object:, name:} }
  let(:object) do
    user = User.new
    user.errors.add(:base, "test error")
    user
  end
  let(:name) { nil }

  it "renders when object has errors" do
    expect(instance.render?).to be_truthy
    expect(component).to be_present
    expect(component).to have_css('[role="alert"]')
  end

  context "no errors" do
    let(:object) { FactoryBot.build(:user) }
    it "doesn't render" do
      expect(object).to be_valid
      expect(instance.render?).to be_falsey
    end
  end
end
