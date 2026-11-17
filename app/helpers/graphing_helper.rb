# frozen_string_literal: true

module GraphingHelper
  def time_range_counts(collection:, column: "created_at", time_range: nil)
    collection_grouped(collection: collection, column: column, time_range: time_range).count
  end

  # What time_range_counts returns for a collection with no matching rows, without a
  # relation to run a query through. series: because groupdate only fills the whole range
  # for a relation - an enumerable gets the buckets it found, which for [] is none
  def empty_time_range_counts(time_range = @time_range)
    [].send(group_by_method(time_range), **grouping(time_range), series: true) { it }
      .transform_values { 0 }
  end

  def time_range_length(time_range)
    time_range.last - time_range.first
  end

  def group_by_method(time_range)
    case time_range_length(time_range)
    when ...(1.hour + 1) then :group_by_minute
    when ...5.days then :group_by_hour
    when ...5_000_000 then :group_by_day # around 60 days
    when ...52.weeks then :group_by_week
    else :group_by_month
    end
  end

  def group_by_format(time_range, group_period = nil)
    group_period ||= group_by_method(time_range)
    if group_period == :group_by_minute
      "%l:%M %p"
    elsif group_period == :group_by_hour
      "%a%l %p"
    elsif group_period == :group_by_month
      "%Y-%-m"
    elsif group_period == :group_by_day && (time_range_length(time_range) < 10.days)
      "%a %-m-%-d"
    else # Default handling
      "%Y-%-m-%-d"
    end
  end

  private

  def collection_grouped(collection:, column: "created_at", time_range: nil)
    time_range ||= @time_range
    # A default_scope order can't sit beside the GROUP BY
    collection.unscope(:order).send(group_by_method(time_range), column, **grouping(time_range))
  end

  # Shared with empty_time_range_counts, whose whole contract is producing the same
  # buckets: range is what makes groupdate emit the empty ones
  def grouping(time_range)
    {range: time_range, format: group_by_format(time_range), time_zone: Time.zone}
  end
end
