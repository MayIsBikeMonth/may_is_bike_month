# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Modal::Component, type: :component do
  it "renders dialog with title" do
    component = render_inline(described_class.new(id: "test-modal", title: "Test Modal")) do |modal|
      modal.with_body { "Modal body" }
    end

    expect(component).to have_css("dialog")
    expect(component).to have_text("Test Modal")
    expect(component).to have_text("Modal body")
  end

  it "renders with custom id" do
    component = render_inline(described_class.new(id: "my-modal", title: "Test")) do |modal|
      modal.with_body { "content" }
    end

    expect(component).to have_css("#my-modal")
  end
end
