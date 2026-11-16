# frozen_string_literal: true

class ApplicationComponentPreview < ViewComponent::Preview
  include ActionView::Context

  # Static stand-ins for the lookup tables upstream previews read, which this app doesn't have
  CYCLE_TYPES = [["Bike", "bike"], ["Tandem", "tandem"], ["Unicycle", "unicycle"], ["Tricycle", "tricycle"],
    ["Recumbent", "recumbent"], ["Bike Trailer", "trailer"], ["Cargo Bike (front storage)", "cargo"],
    ["Tall Bike (multiple frames fused together)", "tall-bike"], ["Penny Farthing", "penny-farthing"],
    ["Cargo Bike Rear (e.g. longtail)", "cargo-rear"], ["Trail behind (half bike)", "trail-behind"],
    ["Balance Bike", "balance-bike"]].freeze
  PRIMARY_ACTIVITIES = [["Commuting", 1], ["Cyclocross", 2], ["Gravel", 3], ["Mountain", 4], ["Road", 5],
    ["Touring", 6]].freeze
  WHEEL_SIZES = [["700c / 29\"", 1], ["650b / 27.5\"", 2], ["26\"", 3], ["24\"", 4], ["20\"", 5], ["16\"", 6]].freeze

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

  # Falls back so a fresh database renders, not raises
  def lookbook_user
    @lookbook_user ||= User.find_by(id: ENV.fetch("LOOKBOOK_USER_ID", 1)) || User.first
  end

  private

  def production_notice(rendered)
    render(UI::Alerts::Base::Component.new(kind: :error,
      text: "This preview renders a real #{rendered}, so it's disabled in production."))
  end

  def missing_notice(needed)
    render(UI::Alerts::Base::Component.new(kind: :warning,
      text: "Nothing to preview — this environment doesn't have #{needed}."))
  end

  def template
    ActionView::Base.new(
      ActionView::LookupContext.new(ActionController::Base.view_paths),
      {},
      ApplicationController.new
    )
  end
end
