# frozen_string_literal: true

module UI
  module DefinitionList
    class ComponentPreview < ApplicationComponentPreview
      # @!group Variants
      def default
        render(UI::DefinitionList::Component.new) do |list|
          list.with_entry(label: "Competition") { "May is Bike Month 2026" }
          list.with_entry(label: "Rider") { "Margot Foster" }
          list.with_entry(label: "Email") { "margotfoster@example.com" }
          list.with_entry(label: "Primary bike") { "Surly Cross-Check" }
          list.with_entry(label: "Activities") { "42" }
          list.with_entry(label: "Notes") do
            "Kombucha lumbersexual jawn DSA tumeric kogi cardigan succulents. Chambray farm-to-table chia, sus artisan kogi edison bulb helvetica fixie live-edge tonx lo-fi roof party banjo tote bag. Pork belly vaporware irony, synth typewriter activated charcoal fashion axe banjo cliche blue bottle vinyl beard la croix af flannel."
          end
          list.with_entry(label: "An exceptionally long label that always renders full-width regardless of container width, so it doesn't squeeze the label column for other rows", full_width: true) do
            "short"
          end
        end
      end

      def bordered
        render(UI::DefinitionList::Component.new(bordered: true)) do |list|
          list.with_entry(label: "Competition") { "May is Bike Month 2026" }
          list.with_entry(label: "Rider") { "Margot Foster" }
          list.with_entry(label: "Email") { "margotfoster@example.com" }
          list.with_entry(label: "Primary bike") { "Surly Cross-Check" }
          list.with_entry(label: "Activities") { "42" }
          list.with_entry(label: "Notes") do
            "Kombucha lumbersexual jawn DSA tumeric kogi cardigan succulents. Chambray farm-to-table chia, sus artisan kogi edison bulb helvetica fixie live-edge tonx lo-fi roof party banjo tote bag. Pork belly vaporware irony, synth typewriter activated charcoal fashion axe banjo cliche blue bottle vinyl beard la croix af flannel."
          end
        end
      end

      def three_up
        render_with_template(template: "ui/definition_list/component_preview/three_up")
      end
      # @!endgroup
    end
  end
end
