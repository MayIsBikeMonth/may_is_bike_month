# frozen_string_literal: true

module UI::DefinitionList
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(UI::DefinitionList::Component.new) do |list|
        list.with_entry(label: "Application for") { "Backend Developer" }
        list.with_entry(label: "Email address") { "margotfoster@example.com" }
        list.with_entry(label: "Salary expectation") { "$120,000" }
        list.with_entry(label: "About") do
          "Fugiat ipsum ipsum deserunt culpa aute sint do nostrud anim incididunt cillum culpa consequat. Excepteur qui ipsum aliquip consequat sint. Sit id mollit nulla mollit nostrud in ea officia proident. Irure nostrud pariatur mollit ad adipisicing reprehenderit deserunt qui eu."
        end
        list.with_entry(label: "An exceptionally long label that should be clamped to twenty percent of the container width and wrap onto multiple lines") do
          "short"
        end
      end
    end
  end
end
