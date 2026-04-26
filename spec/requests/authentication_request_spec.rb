# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :request do
  describe "devise user routes" do
    context "sign up" do
      it "redirect" do
        get "/users/sign_up"
        expect(response.code).to eq "404"
      end
    end

    context "sign in" do
      it "redirect" do
        get "/users/sign_in"
        expect(response).to redirect_to root_path
      end
    end
  end

  describe "/users/auth/strava post" do
    it "redirects" do
      post "/users/auth/strava"
      expect(response).to redirect_to(/https:..www.strava.com/)
    end
  end

  describe "users/auth/strava/callback get" do
    let(:path) { "/users/auth/strava/callback" }
    let(:omniauth_data) do
      {
        provider: "strava",
        uid: "2430215",
        info: {
          name: "seth herr",
          first_name: "seth",
          last_name: "herr",
          email: nil,
          location: "San Francisco California",
          image: "https://dgalywyr863hv.cloudfront.net/pictures/athletes/2430215/2807433/6/large.jpg"
        },
        credentials: {
          token: "fake-token",
          refresh_token: "fake-refresh",
          expires_at: (Time.current + 20600).to_i,
          expires: true
        },
        extra: {
          recent_ride_totals: nil,
          ytd_ride_totals: nil,
          all_ride_totals: nil,
          raw_info: {
            id: 2430215,
            username: "sethherr",
            resource_state: 3,
            firstname: "seth",
            lastname: "herr",
            bio: "",
            city: "San Francisco",
            state: "California",
            country: "United States",
            sex: "M",
            premium: true,
            summit: true,
            created_at: "2013-06-26T20:41:15Z",
            updated_at: "2024-04-08T21:25:21Z",
            badge_type_id: 1,
            weight: 72.5747,
            profile_medium: "https://dgalywyr863hv.cloudfront.net/pictures/athletes/2430215/2807433/6/medium.jpg",
            profile: "https://dgalywyr863hv.cloudfront.net/pictures/athletes/2430215/2807433/6/large.jpg",
            friend: nil,
            follower: nil,
            blocked: false,
            can_follow: true,
            follower_count: 160,
            friend_count: 142,
            mutual_friend_count: 0,
            athlete_type: 0,
            date_preference: "%m/%d/%Y",
            measurement_preference: "feet",
            clubs: []
          }
        }
      }
    end

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.add_mock(:strava, omniauth_data)
    end
    let!(:competition) { FactoryBot.create(:competition, current: true) }

    define_method(:signup_and_get_user) do |signup_cookies = {}|
      signup_cookies.each { |k, v| cookies[k] = v }
      expect { post path }.to change(User, :count).by 1
      User.last
    end

    it "auths" do
      user = signup_and_get_user
      expect(user.strava_id).to eq "2430215"
      expect(user.strava_username).to eq "sethherr"
      expect(user.display_name).to eq "seth herr"
      expect(user.strava_auth.keys).to match_array(%w[token refresh_token expires_at])
      expect(user.role).to eq "basic_user"
      expect(user.strava_info).to eq omniauth_data.dig(:extra, :raw_info).as_json
      expect(user.last_sign_in_at).to be_present
      expect(user.competition_users.pluck(:competition_id)).to eq([competition.id])
      expect(user.theme).to eq "theme_system"
    end

    describe "sign-in tracking" do
      let(:initial_time) { Time.current.change(usec: 0) - 1.day }
      let(:return_time) { initial_time + 6.hours }

      it "sets last_sign_in_at on initial auth and updates it on subsequent auth" do
        user = travel_to(initial_time) { signup_and_get_user }
        expect(user.last_sign_in_at).to match_time(initial_time)
        expect(user.current_sign_in_at).to match_time(initial_time)
        expect(user.sign_in_count).to eq 1

        reset!
        OmniAuth.config.add_mock(:strava, omniauth_data)
        travel_to(return_time) { post path }
        user.reload
        expect(user.last_sign_in_at).to match_time(initial_time)
        expect(user.current_sign_in_at).to match_time(return_time)
        expect(user.sign_in_count).to eq 2
      end
    end

    context "with signup_theme cookie set to dark" do
      it "sets user theme to theme_dark" do
        expect(signup_and_get_user(signup_theme: "dark").theme).to eq "theme_dark"
      end
    end

    context "with signup_theme cookie set to light" do
      it "sets user theme to theme_light" do
        expect(signup_and_get_user(signup_theme: "light").theme).to eq "theme_light"
      end
    end

    context "with signup_unit cookie set to metric" do
      it "sets user unit to metric" do
        expect(signup_and_get_user(signup_unit: "metric").unit).to eq "metric"
      end
    end

    context "with signup_unit cookie set to imperial" do
      it "sets user unit to imperial" do
        expect(signup_and_get_user(signup_unit: "imperial").unit).to eq "imperial"
      end
    end
  end
end
