# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ApplicationComponentHelper

  DEFAULT_INITIAL_UNIT = "imperial"

  def raise_if_invalid_value!(attribute, value, options = {})
    return if options.include?(value)

    raise ArgumentError, "Invalid #{attribute}: #{value}. Must be one of: #{options.join(", ")}"
  end

  private

  def unit_class_metric
    "unit-metric #{(@initial_unit == "metric") ? "" : "hidden"}"
  end

  def unit_class_imperial
    "unit-imperial #{(@initial_unit == "imperial") ? "" : "hidden"}"
  end

  # Not the right place for this, but good enuf for now. Also in ApplicationHelper
  def meters_to_feet(number)
    number * 3.28084
  end

  # Not the right place for this, but good enuf for now. Also in ApplicationHelper
  def meters_to_miles(number)
    number / 1609.344
  end
end
