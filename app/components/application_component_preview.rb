# frozen_string_literal: true

class ApplicationComponentPreview < ViewComponent::Preview
  include ActionView::Context

  # Don't include this class in Lookbook
  def self.abstract_class
    name == "ApplicationComponentPreview"
  end

  def self.inherited(subclass)
    super
    subclass.layout "component_preview"
  end

  def preview_competition_user
    CompetitionUser.find(ENV.fetch("LOOKBOOK_COMPETITION_USER_ID", 1))
  end

  private

  def template
    ActionView::Base.new(
      ActionView::LookupContext.new(ActionController::Base.view_paths),
      {},
      ApplicationController.new
    )
  end
end
