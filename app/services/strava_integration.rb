# frozen_string_literal: true

class StravaIntegration
  CLIENT_ID = ENV["STRAVA_CLIENT_ID"]
  SECRET = ENV["STRAVA_SECRET"]
  STRAVA_BASE_URL = "https://www.strava.com"

  class << self
    def refresh_access_token(refresh_token)
      response = connection.post(token_path("refresh_token")) do |req|
        req.body = {refresh_token:, client_secret: SECRET, client_id: CLIENT_ID}.to_json
      end
      {json: JSON.parse(response.body), status: response.status}.with_indifferent_access
    end

    def get_activities(access_token, parameters: {})
      response = athlete_connection(access_token).get("/api/v3/athlete/activities?#{parameters.to_query}")
      {json: JSON.parse(response.body), status: response.status}.with_indifferent_access
    end

    private

    def connection
      @conn ||= Faraday.new(url: STRAVA_BASE_URL) do |conn|
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

    def token_path(grant_type)
      "/oauth/token?grant_type=#{grant_type}"
    end

    def redirect_uri
      "#{ENV.fetch("BASE_URL", "https://mayisbikemonth.org")}/oauth/callbacks/strava"
    end
  end
end
