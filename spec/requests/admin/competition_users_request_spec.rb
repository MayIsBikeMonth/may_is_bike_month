require "rails_helper"

base_url = "/admin/competition_users"
RSpec.describe base_url, type: :request do
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to root_url
      expect(session[:user_return_to]).to eq "/admin/competition_users"
    end

    context "signed in" do
      include_context :logged_in_as_user
      it "flash errors" do
        get base_url
        expect(response).to redirect_to root_url
        expect(flash[:error]).to be_present
      end
    end
  end

  context "signed in as admin" do
    include_context :logged_in_as_admin
    let(:competition_user) { FactoryBot.create(:competition_user) }

    describe "index" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/competition_users/index")
        expect(response.body).to include("render_chart=true")
        expect(assigns(:render_chart)).to be_falsey
      end
      context "with render_chart=true" do
        it "renders the chart" do
          get "#{base_url}?render_chart=true&period=week"
          expect(response.code).to eq "200"
          expect(assigns(:render_chart)).to be_truthy
          expect(assigns(:matching_competition_users)).not_to be_nil
          expect(response.body).to include("render_chart=false")
        end
      end
      context "with things" do
        let!(:competition_user1) { FactoryBot.create(:competition_user, competition: competition1) }
        let!(:competition_user2) { FactoryBot.create(:competition_user, competition: competition2) }
        let(:competition1) { FactoryBot.create(:competition, start_date: Date.parse("2024-05-01")) }
        let(:competition2) { FactoryBot.create(:competition) }

        it "defaults to the current competition" do
          expect(Competition.count).to eq 2
          expect(Competition.current).to eq competition2

          get base_url
          expect(response.code).to eq "200"
          expect(response).to render_template("admin/competition_users/index")
          expect(assigns(:competition_subject)).to eq competition2
          expect(assigns(:competition_users).pluck(:id)).to eq([competition_user2.id])
        end

        it "filters by search_competition_id when provided" do
          get "#{base_url}?search_competition_id=#{competition1.id}"
          expect(response.code).to eq "200"
          expect(assigns(:competition_subject)).to eq competition1
          expect(assigns(:competition_users).pluck(:id)).to eq([competition_user1.id])
        end

        it "shows all competitions when search_competition_id=all" do
          get "#{base_url}?search_competition_id=all"
          expect(response.code).to eq "200"
          expect(assigns(:competition_subject)).to be_nil
          expect(assigns(:competition_users).pluck(:id)).to match_array([competition_user1.id, competition_user2.id])
        end

        it "filters by user within the default current competition" do
          get "#{base_url}?user=#{competition_user2.user.slug}"
          expect(response.code).to eq "200"
          expect(assigns(:user_subject).id).to eq competition_user2.user_id
          expect(assigns(:competition_users).pluck(:id)).to eq([competition_user2.id])
          expect(response.body).to include("for user:")
          expect(response.body).to include(competition_user2.user.display_name)
        end

        it "renders missing-user message for unknown slugs" do
          get "#{base_url}?user=unknown-slug"
          expect(response.code).to eq "200"
          expect(assigns(:user_subject)).to be_nil
          expect(response.body).to include(%(User "unknown-slug" missing))
        end
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{competition_user.id}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/competition_users/edit")
      end
    end

    describe "update" do
      let(:valid_params) { {display_name: "New Name", included_in_competition: false} }
      it "renders" do
        patch "#{base_url}/#{competition_user.id}", params: {
          competition_user: valid_params
        }
        expect(flash[:success]).to be_present
        expect(response).to redirect_to admin_competition_users_path
        expect(competition_user.reload.display_name).to eq "New Name"
        expect(competition_user.included_in_competition).to be_falsey
      end
    end
  end
end
