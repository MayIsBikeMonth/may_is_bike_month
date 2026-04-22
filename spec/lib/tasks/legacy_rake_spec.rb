require "rails_helper"
Rails.application.load_tasks unless defined?(RakeLegacy)

RSpec.describe RakeLegacy do
  let(:year) { 2023 }
  let(:yaml_path) { Rails.root.join("tmp/legacy_test_#{year}.yml") }
  def week(miles, feet) = {"miles" => miles, "feet" => feet}
  let(:yaml_data) do
    {
      "source_url" => "https://example.com/spreadsheet",
      "riders" => {
        "Alice" => {"week_1" => week(10.0, 100), "week_2" => week(20.0, 200), "week_3" => week(0.0, 0),
                    "week_4" => week(5.0, 50), "week_5" => week(15.0, 150)},
        "Bob" => {"week_1" => week(5.0, 50), "week_2" => week(0.0, 0), "week_3" => week(10.0, 100),
                  "week_4" => week(0.0, 0), "week_5" => week(0.0, 0)}
      }
    }
  end

  before do
    File.write(yaml_path, yaml_data.to_yaml)
    allow(described_class).to receive(:yaml_path).with(year).and_return(yaml_path)
    Sidekiq::Job.clear_all
  end
  after { File.delete(yaml_path) if File.exist?(yaml_path) }

  describe ".import" do
    it "creates the legacy competition, users, and enqueues update jobs" do
      expect { described_class.import(year:) }
        .to change(Competition, :count).by(1)
        .and change(CompetitionUser, :count).by(2)
        .and change(User, :count).by(2)
        .and change(UpdateCompetitionUserJob.jobs, :count).by(2)

      competition = Competition.last
      expect(competition).to be_legacy
      expect(competition.start_date).to eq Date.new(year, 5, 1)
      expect(competition.end_date).to eq Date.new(year, 5, 31)
      expect(competition.legacy_url).to eq "https://example.com/spreadsheet"

      alice_cu = competition.competition_users.joins(:user).find_by(users: {display_name: "Alice"})
      expect(alice_cu.display_name).to eq "Alice"
      expect(alice_cu.score_data["distance"]).to be_within(0.01).of(50.0 * 1609.344)
      expect(alice_cu.score_data["elevation"]).to be_within(0.01).of(500 * 0.3048)
      expect(alice_cu.score_data["periods"].size).to eq 5
      expect(alice_cu.score_data["periods"].first["distance"]).to be_within(0.01).of(10.0 * 1609.344)
    end

    it "returns the rider count" do
      expect(described_class.import(year:)).to eq 2
    end

    context "when run twice" do
      before { described_class.import(year:) }

      it "is idempotent" do
        expect { described_class.import(year:) }.not_to change(Competition, :count)
        expect { described_class.import(year:) }.not_to change(CompetitionUser, :count)
      end

      it "updates legacy_url if the yaml changed" do
        yaml_data["source_url"] = "https://example.com/updated"
        File.write(yaml_path, yaml_data.to_yaml)
        described_class.import(year:)
        expect(Competition.last.legacy_url).to eq "https://example.com/updated"
      end
    end

    context "when a user already exists with the same display_name" do
      let!(:alice) { FactoryBot.create(:user, display_name: "Alice") }

      it "reuses the existing user" do
        expect { described_class.import(year:) }.to change(User, :count).by(1)
        expect(CompetitionUser.joins(:user).where(users: {id: alice.id}).count).to eq 1
      end
    end

    context "when the yaml file is missing" do
      before { File.delete(yaml_path) }

      it "raises" do
        expect { described_class.import(year:) }.to raise_error(/Legacy data not found/)
      end
    end

    context "when a rider has missing weeks" do
      let(:yaml_data) do
        {"source_url" => "x", "riders" => {"Alice" => {"week_1" => week(10.0, 100), "week_2" => week(20.0, 200)}}}
      end

      it "raises" do
        expect { described_class.import(year:) }.to raise_error(/Alice has weeks/)
      end
    end
  end

  describe ".check_matches" do
    context "when all names match existing users" do
      before do
        FactoryBot.create(:user, display_name: "Alice")
        FactoryBot.create(:user, display_name: "Bob")
      end

      it "reports all matched" do
        expect { described_class.check_matches(year:) }.to output(/All 2 legacy names matched/).to_stdout
      end
    end

    context "when some names are unmatched" do
      before { FactoryBot.create(:user, display_name: "Alice") }

      it "lists unmatched names" do
        expect { described_class.check_matches(year:) }.to output(/Unmatched names:.*Bob/m).to_stdout
      end
    end
  end
end
