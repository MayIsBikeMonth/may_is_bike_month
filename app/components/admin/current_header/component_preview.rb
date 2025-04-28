# frozen_string_literal: true

module Admin::CurrentHeader
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(Admin::CurrentHeader::Component.new(**opts))
    end

    private

    def opts
      {
        viewing: "competition_users",
        include_competition_select: true,
        competition_subject: nil,
        searchable_competitions: Competition.order(start_date: :desc),
        render_period: false,
        s_params: {}
      }
    end
  end
end
