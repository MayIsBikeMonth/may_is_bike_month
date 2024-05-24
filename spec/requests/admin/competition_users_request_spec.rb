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
    describe "index" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/competition_users/index")
      end
      context "with things" do
        let!(:competition_user1) { FactoryBot.create(:competition_user) }
        let!(:competition_user2) { FactoryBot.create(:competition_user) }
        let(:competition1) { competition_user1.competition }
        it "renders" do
          expect(Competition.count).to eq 2
          get base_url
          expect(response.code).to eq "200"
          expect(response).to render_template("admin/competition_users/index")
          expect(assigns(:competition_users).pluck(:id)).to match_array([competition_user1.id, competition_user2.id])

          get "#{base_url}?search_competition_id=#{competition1.id}"
          expect(response.code).to eq "200"
          expect(response).to render_template("admin/competition_users/index")
          expect(assigns(:competition_subject).id).to eq competition1.id
          expect(assigns(:competition_users).pluck(:id)).to eq([competition_user1.id])
        end
      end
    end

    describe "update" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/competition_users/index")
      end
    end
  end
end
