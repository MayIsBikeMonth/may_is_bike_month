require "rails_helper"

RSpec.describe Competition, type: :model do
  describe "factory" do
    let(:competition) { FactoryBot.create(:competition) }
    it "is valid" do
      expect(competition).to be_valid
    end
  end
end
