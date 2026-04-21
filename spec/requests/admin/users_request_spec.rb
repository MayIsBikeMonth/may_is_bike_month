require "rails_helper"

base_url = "/admin/users"
RSpec.describe base_url, type: :request do
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to root_url
      expect(session[:user_return_to]).to eq "/admin/users"
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
      context "with multiple users" do
        let!(:older_user) { FactoryBot.create(:user, created_at: Time.current - 2.days, last_sign_in_at: Time.current - 1.hour) }
        let!(:newer_user) { FactoryBot.create(:user, created_at: Time.current - 1.hour, last_sign_in_at: Time.current - 2.days) }
        let!(:competition_user) { FactoryBot.create(:competition_user, user: newer_user) }

        it "renders, sorts, and links to the user-scoped competition_users" do
          get base_url
          expect(response.code).to eq "200"
          expect(response).to render_template("admin/users/index")
          ids = assigns(:users).pluck(:id)
          expect(ids.index(newer_user.id)).to be < ids.index(older_user.id)
          expect(response.body).to include(admin_competition_users_path(user: newer_user.slug))

          get "#{base_url}?sort=last_sign_in_at&direction=desc"
          expect(response.code).to eq "200"
          expect(assigns(:sort_column)).to eq "last_sign_in_at"
          ids = assigns(:users).pluck(:id)
          expect(ids.index(older_user.id)).to be < ids.index(newer_user.id)
        end
      end
    end
  end
end
