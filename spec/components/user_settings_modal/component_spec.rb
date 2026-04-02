# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserSettingsModal::Component, type: :component do
  let(:user) { build(:user) }

  it "renders UI::Modal with settings content" do
    component = render_inline(described_class.new(current_user: user)) do |modal|
      modal.with_trigger { "Open Settings" }
    end

    expect(component).to have_css("dialog")
    expect(component).to have_text("Settings")
    expect(component).to have_text("Open Settings")
    expect(component).to have_text("Theme")
    expect(component).to have_text("Units")
  end

  it "defaults theme to system" do
    component = render_inline(described_class.new(current_user: user))

    expect(component).to have_css('[data-theme-current-value="system"]')
  end

  it "renders theme options" do
    component = render_inline(described_class.new(current_user: user))

    expect(component).to have_css('[data-theme="theme_light"]')
    expect(component).to have_css('[data-theme="theme_dark"]')
    expect(component).to have_css('[data-theme="system"]')
  end

  it "renders unit options" do
    component = render_inline(described_class.new(current_user: user))

    expect(component).to have_css('[data-unit="imperial"]')
    expect(component).to have_css('[data-unit="metric"]')
  end
end
