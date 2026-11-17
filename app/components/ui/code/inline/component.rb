# frozen_string_literal: true

module UI
  module Code
    module Inline
      class Component < ApplicationComponent
        def initialize(text:, small: false, word_break: true)
          @text = text
          @small = small
          @word_break = word_break
        end

        def call = tag.code(@text, class: classes)

        private

        # The resets beat bootstrap's `code` rule, on pages loading the legacy stylesheet
        def classes = ["rounded-none bg-transparent p-0 text-pink-600 dark:text-pink-400", @small ? "text-xs" : "text-sm", @word_break ? "wrap-break-word" : "break-keep"]
      end
    end
  end
end
