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

  def container_for(user)
    activity_containers.find { |c| c.find(:xpath, "ancestor::*[@data-user-slug][1]")["data-user-slug"] == user.slug }
  end

  it "hides activities by default and toggles via Show/Hide all and per-user buttons" do
    expect(activity_containers.size).to eq 2
    expect(activity_containers).to all(satisfy { |c| !visible?(c) })
    expect(page).to have_button("Show all activities")

    click_button("Show all activities")

    expect(activity_containers).to all(satisfy { |c| visible?(c) })
    expect(find_button("Show all activities")["aria-pressed"]).to eq "true"

    click_button("Hide all activities")

    expect(activity_containers).to all(satisfy { |c| !visible?(c) })
    expect(find_button("Show all activities")["aria-pressed"]).to eq "false"

    click_button("Alice")

    expect(visible?(container_for(alice))).to be true
    expect(visible?(container_for(bob))).to be false
    expect(find_button("Alice")["aria-pressed"]).to eq "true"

    click_button("Alice")

    expect(visible?(container_for(alice))).to be false
    expect(find_button("Alice")["aria-pressed"]).to eq "false"
  end

  context "when no user has activities" do
    let!(:alice_activity) { nil }
    let!(:bob_activity) { nil }

    it "hides the Show all activities button" do
      expect(page).not_to have_button("Show all activities")
    end
  end
end
