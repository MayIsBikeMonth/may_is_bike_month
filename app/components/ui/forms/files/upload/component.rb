# frozen_string_literal: true

module UI
  module Forms
    module Files
      module Upload
        # direct_upload_url: with JS, uploads on pick and posts the blob's signed id instead of
        # the bytes. The field still renders as an ordinary one, so it posts the file when JS
        # doesn't run - the controller drops its name only once it's driving the upload.
        class Component < ApplicationComponent
          def initialize(form_builder:, attribute:, accept: nil, camera: nil, direct_upload_url: nil, html_options: {})
            @form_builder = form_builder
            @attribute = attribute
            @accept = accept
            @camera = camera

            @attachment_url = attached_url

            @direct_upload_url = direct_upload_url
            # Carries the blob the browser uploaded. Scoped to the form builder like every other
            # field here, so two of these on one page don't collide on the same param
            @signed_id_field = "#{form_builder.object_name}[#{attribute}_signed_id]" if direct_upload_url.present?
            @html_options = html_options
          end

          private

          def record
            @form_builder.object
          end

          def attachment
            record.try(@attribute)
          end

          # The record's own `<attribute>_url` wins where it defines one -- several add a
          # dev fallback or serve a processed copy that reaching for the blob would skip.
          def attached_url
            return unless attached?

            record.respond_to?(:"#{@attribute}_url") ? record.public_send(:"#{@attribute}_url") : helpers.url_for(attachment)
          end

          def attached?
            record.present? && attachment.respond_to?(:attached?) && attachment.attached?
          end
        end
      end
    end
  end
end
