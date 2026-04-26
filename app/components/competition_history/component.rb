# frozen_string_literal: true

module CompetitionHistory
  class Component < ApplicationComponent
    def initialize(competitions:)
      @competitions = competitions
    end

    private

    def rows
      @rows ||= @competitions.map { |competition| Row.new(competition:) }
    end

    def max_rider_count
      @max_rider_count ||= rows.map(&:rider_count).max.to_i
    end

    def max_distance_meters
      @max_distance_meters ||= rows.map(&:distance_meters).max.to_f
    end

    def max_elevation_meters
      @max_elevation_meters ||= rows.map(&:elevation_meters).max.to_f
    end

    def max_everyday_count
      @max_everyday_count ||= rows.filter_map(&:everyday_count).max.to_i
    end

    def bar_pct(value, max)
      return 0 if max.to_f.zero?
      ((value.to_f / max) * 100).clamp(4, 100)
    end

    def miles_display(meters)
      number_display(meters_to_miles(meters), round_to: 0)
    end

    def feet_display(meters)
      number_display(meters_to_feet(meters), round_to: 0)
    end

    class Row
      attr_reader :competition

      def initialize(competition:)
        @competition = competition
      end

      def year = competition.year
      def display_name = competition.display_name
      def slug = competition.slug
      def legacy? = competition.legacy?

      def first_place = sorted_users[0]
      def second_place = sorted_users[1]
      def third_place = sorted_users[2]

      def last_place
        return nil if sorted_users.size < 4
        sorted_users.last
      end

      def rider_count = sorted_users.size

      def distance_meters
        @distance_meters ||= sorted_users.sum(&:distance_meters).to_f
      end

      def elevation_meters
        @elevation_meters ||= sorted_users.sum(&:elevation_meters).to_f
      end

      def everyday_count
        return nil if legacy?
        @everyday_count ||= sorted_users.count(&:everyday_rider?)
      end

      private

      def sorted_users
        @sorted_users ||= competition.competition_users_included.sort_by(&:score).reverse
      end
    end
  end
end
