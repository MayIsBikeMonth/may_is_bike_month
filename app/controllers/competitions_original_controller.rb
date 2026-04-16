class CompetitionsOriginalController < ApplicationController
  AVAILABLE_YEARS = %w[2024 2025].freeze

  def show
    @year = params[:id]
    raise ActionController::RoutingError, "Not Found" unless AVAILABLE_YEARS.include?(@year)
    @other_year = (AVAILABLE_YEARS - [@year]).first
    @page_title = "May is Bike Month #{@year}"
    @skip_wrapper_class = true
  end
end
