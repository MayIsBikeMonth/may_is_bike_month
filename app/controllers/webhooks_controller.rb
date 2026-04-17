class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def strava
    if request.post?
      strava_receive_event
    else
      strava_verify_subscription
    end
  end

  private

  def strava_verify_subscription
    if params["hub.verify_token"].present? &&
        params["hub.verify_token"] == StravaIntegration.webhook_verify_token
      render json: {"hub.challenge" => params["hub.challenge"]}, status: :ok
    else
      head :forbidden
    end
  end

  def strava_receive_event
    user = User.find_by(strava_id: params["owner_id"].to_s)
    if user
      strava_request = StravaRequest.create!(
        user:,
        kind: :incoming_webhook,
        parameters: params.slice(:object_type, :aspect_type, :object_id,
          :owner_id, :subscription_id, :updates).as_json
      )
      ProcessStravaWebhookJob.perform_async(strava_request.id)
    end
    head :ok
  end
end
