require "rails_helper"

RSpec.describe StravaRequest, type: :model do
  describe "update_due?" do
    it "is true" do
      expect(described_class.update_due?).to be_truthy
    end
  end

  describe "request" do
  end
end
