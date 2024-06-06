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
    let(:competition_user)  {FactoryBot.create(:competition_user) }

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
