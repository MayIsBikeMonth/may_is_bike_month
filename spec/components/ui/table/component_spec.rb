# frozen_string_literal: true

require "rails_helper"
require "ostruct"

RSpec.describe UI::Table::Component, type: :component do
  let(:records) do
    [
      OpenStruct.new(name: "Alice", email: "alice@example.com"),
      OpenStruct.new(name: "Bob", email: "bob@example.com")
    ]
  end

  let(:component) do
    render_inline(described_class.new(records:)) do |table|
      table.column(label: "Name") { |r| r.name }
      table.column(label: "Email") { |r| r.email }
    end
  end

  it "renders a table with headers and rows" do
    expect(component).to have_css("table")
    expect(component).to have_css("th", text: "Name")
    expect(component).to have_css("th", text: "Email")
    expect(component).to have_css("td", text: "Alice")
    expect(component).to have_css("td", text: "bob@example.com")
  end

  context "with custom classes" do
    let(:component) do
      render_inline(described_class.new(records:, classes: "custom-class")) do |table|
        table.column(label: "Name") { |r| r.name }
      end
    end

    it "includes custom classes on the table" do
      html = component.to_html
      expect(html).to include("custom-class")
      expect(html).to include("min-w-full")
    end
  end

  it "renders components inside column blocks" do
    result = render_inline(described_class.new(records:)) do |table|
      table.column(label: "Name") { |r| r.name }
      table.column(label: "Role") { |r| render(UI::Badge::Component.new(text: "admin", color: :purple, size: :sm)) }
    end

    expect(result).to have_css("th", text: "Name")
    expect(result).to have_css("th", text: "Role")
    expect(result).to have_css("td", text: "Alice")
    expect(result).to have_css("td span", text: "admin")
  end

  context "with sortable columns" do
    before do
      allow_any_instance_of(described_class).to receive(:sortable_url).and_return("/")
    end

    it "renders sortable headers with link class and active state" do
      result = render_inline(described_class.new(records:, sort: "name", sort_direction: "desc")) do |table|
        table.column(sortable: "name") { |r| r.name }
        table.column(sortable: "email") { |r| r.email }
      end

      expect(result).to have_css("th a.twlink.active", text: /Name/)
      expect(result).to have_css("th a.twlink", text: /Email/)
      expect(result).not_to have_css("th a.active", text: /Email/)
    end
  end

  context "with unbordered" do
    it "removes border-r and border-t classes from th and td" do
      result = render_inline(described_class.new(records:, unbordered: true)) do |table|
        table.column(label: "Name") { |r| r.name }
      end

      expect(result).not_to have_css("th.border-r.border-t")
      expect(result).not_to have_css("td.border-r")
    end
  end

  context "with cache_key", :caching do
    it "caches each row" do
      users = create_list(:user, 2)
      cache_store = ApplicationController.cache_store

      with_controller_class(ApplicationController) do
        result = render_inline(described_class.new(records: users, cache_key: "test")) do |table|
          table.column(label: "Name") { |u| u.display_name }
          table.column(label: "Email") { |u| u.strava_username }
        end

        expect(result).to have_css("td", text: users.first.display_name)
        expect(result).to have_css("td", text: users.second.strava_username)
        expect(cache_store.instance_variable_get(:@data).size).to eq(2)
      end
    end

    it "namespaces cache keys with a string" do
      users = create_list(:user, 1)
      cache_store = ApplicationController.cache_store

      with_controller_class(ApplicationController) do
        render_inline(described_class.new(records: users, cache_key: "view-a")) do |table|
          table.column(label: "Name") { |u| u.display_name }
        end

        render_inline(described_class.new(records: users, cache_key: "view-b")) do |table|
          table.column(label: "Name") { |u| u.display_name }
        end

        # Same record, different namespace — should produce 2 separate cache entries
        expect(cache_store.instance_variable_get(:@data).size).to eq(2)
      end
    end
  end

  context "with empty records" do
    let(:records) { [] }

    let(:component) do
      render_inline(described_class.new(records:)) do |table|
        table.column(label: "Name") { |r| r.name }
      end
    end

    it "renders headers but no rows" do
      expect(component).to have_css("th", text: "Name")
      expect(component).not_to have_css("td")
    end
  end
end
