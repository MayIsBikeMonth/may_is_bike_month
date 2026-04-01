# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Modal::Component, type: :component do
  it "renders dialog with title" do
    component = render_inline(described_class.new(title: "Test Modal")) do |modal|
      modal.with_body { "Modal body" }
    end

    expect(component).to have_css("dialog")
    expect(component).to have_text("Test Modal")
    expect(component).to have_text("Modal body")
  end

  it "renders with custom id" do
    component = render_inline(described_class.new(title: "Test", id: "my-modal")) do |modal|
      modal.with_body { "content" }
    end

    expect(component).to have_css("#my-modal")
  end

  it "renders trigger slot" do
    component = render_inline(described_class.new(title: "Test")) do |modal|
      modal.with_trigger { "Open" }
      modal.with_body { "content" }
    end

    expect(component).to have_text("Open")
  end
end
