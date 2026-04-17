# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ApplicationComponentHelper

  DEFAULT_INITIAL_UNIT = "imperial"

  def self.meters_to_feet(number)
    number * 3.28084
  end

  def self.meters_to_miles(number)
    number / 1609.344
  end

  def raise_if_invalid_value!(attribute, value, options = {})
    return if options.include?(value)

    raise ArgumentError, "Invalid #{attribute}: #{value}. Must be one of: #{options.join(", ")}"
  end

  private

  def meters_to_feet(number) = self.class.meters_to_feet(number)

  def meters_to_miles(number) = self.class.meters_to_miles(number)
end
