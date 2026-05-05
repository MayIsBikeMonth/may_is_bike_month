# frozen_string_literal: true

require "rails_helper"

# Walks the /history page's user-comparison flow in one example: type into
# the hotwire_combobox, pick options to add chips (which appends columns
# with rank-of-N), reload to confirm the URL persists the selection, then
# remove a chip to confirm the column disappears. State advances through
# clicks; the only re-visit is an explicit reload to verify persistence.
RSpec.describe "Competition history user picker", :js, type: :system do
  let!(:competition) do
    FactoryBot.create(:competition, display_name: "MIBM 2024",
      start_date: Date.parse("2024-05-01"), end_date: Date.parse("2024-05-31"))
  end
  let(:dates) { Competition.dates_strings(competition.start_date, competition.end_date) }

  def make_user(name:, distance:, dates_taken:)
    user = FactoryBot.create(:user, display_name: name)
    FactoryBot.create(:competition_user, competition:, user:,
      score_data: {dates: dates_taken, distance:, elevation: 1_000,
                   periods: competition.periods.map { |p| p.merge(distance: 0, elevation: 0) }})
    user
  end

  let!(:alice) { make_user(name: "Alice Rider", distance: 500_000, dates_taken: dates) }
  let!(:bob) { make_user(name: "Bob Rider", distance: 400_000, dates_taken: dates[0..20]) }
  let!(:carol) { make_user(name: "Carol Rider", distance: 100_000, dates_taken: dates[0..2]) }

  def listbox_option(text)
    find(".hw-combobox__listbox li.hw-combobox__option", text:, visible: true)
  end

  def chip_for(display)
    find("[data-hw-combobox-chip]", text: display)
  end

  def remove_chip(display)
    find("[aria-label='Remove #{display}']").click
  end

  # The selected-user th uses CSS `uppercase`; Selenium's #text returns the
  # rendered (uppercased) form, so match case-insensitively.
  def selected_column_header(text)
    find("th", text: /#{Regexp.escape(text)}/i)
  end

  it "adds and removes user comparison columns via the combobox, persisting via URL" do
    visit history_path

    expect(page).to have_css("h1", text: /MIBM/)
    expect(page).to have_field("View someone specific")
    expect(page).to have_no_css("[data-hw-combobox-chip]")

    fill_in "View someone specific", with: "Alice"
    listbox_option("Alice Rider").click

    # Form auto-submits, page reloads with ?users=alice-rider; chip + column appear.
    expect(page).to have_current_path(/\?users=alice-rider\b/, wait: 5)
    expect(chip_for("Alice Rider")).to be_present
    expect(selected_column_header("Alice Rider")).to be_present
    # Selected user's cell shows their rank with a leading "#".
    expect(page).to have_text(/#\s*1\b/)

    fill_in "View someone specific", with: "Bob"
    listbox_option("Bob Rider").click

    expect(page).to have_current_path(/\?users=alice-rider%2Cbob-rider/, wait: 5)
    expect(chip_for("Bob Rider")).to be_present
    expect(selected_column_header("Bob Rider")).to be_present
    expect(page).to have_text(/#\s*2\b/)

    # URL persists across a hard reload — chips and columns rehydrate.
    visit page.current_url

    expect(chip_for("Alice Rider")).to be_present
    expect(chip_for("Bob Rider")).to be_present
    expect(selected_column_header("Alice Rider")).to be_present
    expect(selected_column_header("Bob Rider")).to be_present

    remove_chip("Alice Rider")

    expect(page).to have_current_path(/\?users=bob-rider\b/, wait: 5)
    expect(page).to have_no_css("[data-hw-combobox-chip]", text: "Alice Rider")
    expect(page).to have_no_css("th", text: /Alice Rider/i)
    expect(chip_for("Bob Rider")).to be_present
  end
end
