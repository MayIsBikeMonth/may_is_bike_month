# frozen_string_literal: true

require "rails_helper"

RSpec.describe Form::Input::Component, type: :component do
  let(:user) { User.new }
  let(:form_builder) do
    MayIsBikeMonthFormBuilder.new(:user, user, ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil), {})
  end
  let(:component) { render_inline(described_class.new(form_builder:, attribute:, kind:, html_options:)) }
  let(:attribute) { :display_name }
  let(:kind) { :text_field }
  let(:html_options) { {} }

  it "renders a text field" do
    expect(component).to have_css("input[type='text'][name='user[display_name]']")
    expect(component.to_html).to include("rounded-lg")
  end

  context "text_area" do
    let(:kind) { :text_area }

    it "renders a textarea" do
      expect(component).to have_css("textarea[name='user[display_name]']")
    end
  end

  context "email_field" do
    let(:kind) { :email_field }
    let(:attribute) { :strava_username }

    it "renders an email input" do
      expect(component).to have_css("input[type='email'][name='user[strava_username]']")
    end
  end

  context "number_field" do
    let(:kind) { :number_field }
    let(:attribute) { :strava_id }

    it "renders a number input" do
      expect(component).to have_css("input[type='number']")
    end
  end

  context "datetime_local_field" do
    let(:kind) { :datetime_local_field }
    let(:attribute) { :last_sign_in_at }

    it "renders a datetime-local input" do
      expect(component).to have_css("input[type='datetime-local']")
    end
  end

  context "date_field" do
    let(:competition) { Competition.new }
    let(:form_builder) do
      MayIsBikeMonthFormBuilder.new(:competition, competition, ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil), {})
    end
    let(:attribute) { :start_date }
    let(:kind) { :date_field }

    it "renders a date input" do
      expect(component).to have_css("input[type='date']")
      expect(component.to_html).to include("rounded-lg")
    end
  end

  context "check_box" do
    let(:competition) { Competition.new }
    let(:form_builder) do
      MayIsBikeMonthFormBuilder.new(:competition, competition, ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil), {})
    end
    let(:attribute) { :current }
    let(:kind) { :check_box }

    it "renders a checkbox with checkbox classes" do
      expect(component).to have_css("input[type='checkbox'][name='competition[current]']")
      expect(component.to_html).to include("h-4 w-4")
      expect(component.to_html).not_to include("rounded-lg")
    end
  end

  context "invalid kind" do
    let(:kind) { :password_field }

    it "falls back to text_field" do
      expect(component).to have_css("input[type='text']")
    end
  end

  context "with html_options" do
    let(:html_options) { {placeholder: "Enter name"} }

    it "passes options through" do
      expect(component).to have_css("input[placeholder='Enter name']")
    end
  end
end
