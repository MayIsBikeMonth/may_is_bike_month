# frozen_string_literal: true

require "rails_helper"

RSpec.describe Form::Group::Component, type: :component do
  let(:user) { User.new }
  let(:form_builder) do
    MayIsBikeMonthFormBuilder.new(:user, user, ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil), {})
  end
  let(:component) { render_inline(described_class.new(form_builder:, attribute:, kind:, label_text:)) }
  let(:attribute) { :display_name }
  let(:kind) { :text_field }
  let(:label_text) { nil }

  it "renders label and input" do
    expect(component).to have_css("label[for='user_display_name']", text: "Display name")
    expect(component).to have_css("input[type='text'][name='user[display_name]']")
  end

  context "with custom label" do
    let(:label_text) { "Display Name" }

    it "uses custom label text" do
      expect(component).to have_css("label", text: "Display Name")
    end
  end

  context "email_field" do
    let(:attribute) { :strava_username }
    let(:kind) { :email_field }

    it "renders email input with label" do
      expect(component).to have_css("label", text: "Strava username")
      expect(component).to have_css("input[type='email']")
    end
  end

  context "text_area" do
    let(:kind) { :text_area }

    it "renders textarea with label" do
      expect(component).to have_css("label", text: "Display name")
      expect(component).to have_css("textarea")
    end
  end
end
