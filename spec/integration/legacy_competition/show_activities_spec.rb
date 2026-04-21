# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Legacy competition show/hide activities", :js, type: :system do
  let!(:competition) do
    FactoryBot.create(:competition, kind: :legacy,
      start_date: Date.parse("2023-05-01"), end_date: Date.parse("2023-05-31"))
  end
  let(:alice) { FactoryBot.create(:user, display_name: "Alice") }
  let(:bob) { FactoryBot.create(:user, display_name: "Bob") }
  let!(:alice_cu) do
    FactoryBot.create(:competition_user, competition:, user: alice,
      score_data: {dates: [], distance: 50_000, elevation: 500,
                   periods: competition.periods.map { |p| p.merge(distance: 10_000, elevation: 100) }})
  end
  let!(:bob_cu) do
    FactoryBot.create(:competition_user, competition:, user: bob,
      score_data: {dates: [], distance: 30_000, elevation: 200,
                   periods: competition.periods.map { |p| p.merge(distance: 6_000, elevation: 40) }})
  end
  let!(:alice_activity) do
    FactoryBot.create(:competition_activity, competition_user: alice_cu,
      distance_meters: 10_000, start_at: Time.parse("2023-05-15T14:00:00Z"))
  end
  let!(:bob_activity) do
    FactoryBot.create(:competition_activity, competition_user: bob_cu,
      distance_meters: 15_000, start_at: Time.parse("2023-05-20T14:00:00Z"))
  end

  def activity_containers
    all(".punch-activities-container", visible: :all)
  end

  def visible?(container)
    !container[:class].split.include?("hidden!")
  end

  before { visit "/competitions/#{competition.slug}" }

  it "hides activities by default and toggles via Show/Hide all" do
    expect(activity_containers.size).to eq 2
    expect(activity_containers).to all(satisfy { |c| !visible?(c) })
    expect(page).to have_button("Show all activities")

    click_button("Show all activities")

    expect(activity_containers).to all(satisfy { |c| visible?(c) })
    expect(find_button("Show all activities")["aria-pressed"]).to eq "true"

    click_button("Hide all activities")

    expect(activity_containers).to all(satisfy { |c| !visible?(c) })
    expect(find_button("Show all activities")["aria-pressed"]).to eq "false"
  end

  context "when no user has activities" do
    let!(:alice_activity) { nil }
    let!(:bob_activity) { nil }

    it "hides the Show all activities button" do
      expect(page).not_to have_button("Show all activities")
    end
  end

  it "toggles a single user's activities when the name button is clicked" do
    click_button("Alice")

    containers = activity_containers
    alice_container = containers.find { |c| c.find(:xpath, "ancestor::*[@data-user-slug][1]")["data-user-slug"] == alice.slug }
    bob_container = containers.find { |c| c.find(:xpath, "ancestor::*[@data-user-slug][1]")["data-user-slug"] == bob.slug }

    expect(visible?(alice_container)).to be true
    expect(visible?(bob_container)).to be false
    expect(find_button("Alice")["aria-pressed"]).to eq "true"

    click_button("Alice")

    expect(visible?(activity_containers.find { |c| c.find(:xpath, "ancestor::*[@data-user-slug][1]")["data-user-slug"] == alice.slug })).to be false
    expect(find_button("Alice")["aria-pressed"]).to eq "false"
  end
end
