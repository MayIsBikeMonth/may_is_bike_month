# frozen_string_literal: true

module StravaIntegration
  extend Functionable

  CLIENT_ID = ENV["STRAVA_CLIENT_ID"]
  SECRET = ENV["STRAVA_SECRET"]
  STRAVA_BASE_URL = "https://www.strava.com"

  def webhook_verify_token
    ENV["STRAVA_WEBHOOK_VERIFY_TOKEN"]
  end

  def refresh_access_token(refresh_token)
    parse_response connection.post(token_path("refresh_token")) { |req|
      req.body = {refresh_token:, client_secret: SECRET, client_id: CLIENT_ID}.to_json
    }
  end

  def get_activities(access_token, parameters: {})
    parse_response athlete_connection(access_token)
      .get("/api/v3/athlete/activities?#{parameters.to_query}")
  end

  def create_webhook_subscription
    parse_response form_connection.post("/api/v3/push_subscriptions") { |req|
      req.body = {
        client_id: CLIENT_ID,
        client_secret: SECRET,
        callback_url: webhook_callback_url,
        verify_token: webhook_verify_token
      }
    }
  end

  def view_webhook_subscriptions
    parse_response form_connection.get("/api/v3/push_subscriptions") { |req|
      req.params = {client_id: CLIENT_ID, client_secret: SECRET}
    }
  end

  def delete_webhook_subscription(subscription_id)
    parse_response form_connection.delete("/api/v3/push_subscriptions/#{subscription_id}") { |req|
      req.params = {client_id: CLIENT_ID, client_secret: SECRET}
    }, with_body: false
  end

  #
  # private below here
  #

  def connection
    Faraday.new(url: STRAVA_BASE_URL) do |conn|
      conn.adapter Faraday.default_adapter
      conn.headers["Content-Type"] = "application/json"
    end
  end

  def athlete_connection(access_token)
    Faraday.new(url: STRAVA_BASE_URL) do |conn|
      conn.adapter Faraday.default_adapter
      conn.headers["Content-Type"] = "application/json"
      conn.headers["Authorization"] = "Bearer #{access_token}"
    end
  end

  def form_connection
    Faraday.new(url: STRAVA_BASE_URL) do |conn|
      conn.request :url_encoded
      conn.adapter Faraday.default_adapter
    end
  end

  def parse_response(response, with_body: true)
    hash = with_body ? {json: JSON.parse(response.body)} : {}
    hash[:status] = response.status
    hash.with_indifferent_access
  end

  def token_path(grant_type)
    "/oauth/token?grant_type=#{grant_type}"
  end

  def redirect_uri
    "#{ENV.fetch("BASE_URL", "https://mayisbikemonth.org")}/oauth/callbacks/strava"
  end

  def webhook_callback_url
    "#{ENV.fetch("BASE_URL", "https://mayisbikemonth.org")}/webhooks/strava"
  end

  conceal :connection, :athlete_connection, :form_connection, :parse_response,
    :token_path, :redirect_uri, :webhook_callback_url
end
