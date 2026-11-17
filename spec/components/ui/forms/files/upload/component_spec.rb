# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Forms::Files::Upload::Component, type: :component do
  let(:record) { User.new }
  let(:form_builder) do
    MayIsBikeMonthFormBuilder.new(:user, record, ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil), {})
  end
  let(:component) { render_inline(described_class.new(form_builder:, attribute:, **options)) }
  let(:attribute) { :avatar }
  let(:options) { {} }

  it "renders the builder's field, labelled, and an empty preview" do
    expect(component).to have_css("input#user_avatar[type='file'][name='user[avatar]']")
    expect(component).to have_css("label[for='user_avatar']", text: "Upload")
    # nothing attached, so the preview ships hidden and srcless, waiting for a pick
    # hidden! because collapse() hides with the important variant, and block is on the same element
    expect(component).to have_css("a[data-ui--forms--files--upload-target='preview'].hidden\\! img")
    expect(component).to have_no_css("[data-ui--forms--files--upload-target='preview'][href]")
    expect(component).to have_no_css("img[src]")
  end

  # A bare input tag renders the same, but leaves the form url-encoded - so the file never posts
  it "renders through the form builder, which makes the form multipart" do
    component

    expect(form_builder.multipart).to be true
  end

  context "with html_options" do
    let(:options) { {html_options: {accept: "image/png", multiple: true}} }

    it "passes options through to the input" do
      expect(component).to have_css("input[type='file'][accept='image/png']")
      expect(component).to have_css("input[multiple]")
    end
  end

  describe "direct_upload_url" do
    let(:options) { {direct_upload_url: "/register/direct_uploads?b_param_token=xyz"} }

    # Rendered as an ordinary file field: without JS it posts the bytes, and the controller
    # drops the name only once it's uploading them itself
    it "renders a named field alongside the signed id it will fill" do
      expect(component).to have_css("input[type='file'][name='user[avatar]']")
      expect(component).to have_css("[data-ui--forms--files--upload-url-value='/register/direct_uploads?b_param_token=xyz']")
      expect(component).to have_css("input[type='hidden'][name='user[avatar_signed_id]'][data-ui--forms--files--upload-target='signedId']", visible: :all)
    end

    context "without one" do
      let(:options) { {} }

      it "renders no signed id field" do
        expect(component).to have_no_css("[data-ui--forms--files--upload-target='signedId']", visible: :all)
        expect(component).to have_no_css("[data-ui--forms--files--upload-url-value]:not([data-ui--forms--files--upload-url-value=''])")
      end
    end
  end
end
