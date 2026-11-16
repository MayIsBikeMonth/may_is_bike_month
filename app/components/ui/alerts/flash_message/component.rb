# frozen_string_literal: true

module UI
  module Alerts
    module FlashMessage
      class Component < ApplicationComponent
        # Devise flashes its failures as :alert
        KIND_ALIASES = {alert: :error}.freeze

        def initialize(flash: {})
          @flash = flash
        end

        private

        # Renders even when empty: #flash-messages is the turbo_stream target for
        # frame updates that carry a flash
        def messages
          @flash.filter_map do |type, message|
            next if !message.is_a?(String) || message.blank?
            {text: message, kind: KIND_ALIASES[type.to_sym] || type}
          end
        end
      end
    end
  end
end
