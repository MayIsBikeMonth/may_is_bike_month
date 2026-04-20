class CompetitionsOriginalController < ApplicationController
  AVAILABLE_YEARS = %w[2024 2025].freeze

  def show
    @year = params[:id]
    raise ActionController::RoutingError, "Not Found" unless AVAILABLE_YEARS.include?(@year)
    @competitions = AVAILABLE_YEARS.reverse.map { |y| Competition.new(start_date: Date.new(y.to_i, 5, 1)) }
    @page_title = "May is Bike Month #{@year}"
  end
end
