# frozen_string_literal: true

module UI
  module Modal
    class Component < ApplicationComponent
      renders_one :trigger
      renders_one :body

      def initialize(title: nil, id: nil)
        @title = title
        @id = id || "modal-#{SecureRandom.hex(4)}"
      end
    end
  end
end
