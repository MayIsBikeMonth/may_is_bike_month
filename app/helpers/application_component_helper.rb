# frozen_string_literal: true

# Shared helper methods for ApplicationComponent and ApplicationHelper
module ApplicationComponentHelper
  def raise_if_invalid_value!(attribute, value, options = {})
    return if options.include?(value)

    raise ArgumentError, "Invalid #{attribute}: #{value}. Must be one of: #{options.join(', ')}"
  end

  def number_display(number, round_to: 0)
    content_tag(:span,
                number_with_delimiter(number.to_f.round(round_to)),
                class: (number.zero? ? 'opacity-50' : nil))
  end

  def meters_to_feet(number)
    number * 3.28084
  end

  def meters_to_miles(number)
    number / 1609.344
  end

  private

  def unit_class_metric
    "unit-metric #{@initial_unit == 'metric' ? '' : 'hidden'}"
  end

  def unit_class_imperial
    "unit-imperial #{@initial_unit == 'imperial' ? '' : 'hidden'}"
  end
end
