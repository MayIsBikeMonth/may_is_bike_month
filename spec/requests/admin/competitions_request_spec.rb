require "rails_helper"

base_url = "/admin/competitions"
RSpec.describe base_url, type: :request do
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to root_url
      expect(session[:user_return_to]).to eq "/admin/competitions"
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
        expect(response).to render_template("admin/competitions/index")
      end
    end

    describe "new" do
      it "renders" do
        get new_admin_competition_path
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/competitions/new")
      end
    end

    describe "create" do
      let(:competition_params) { {start_date: "2026-04-01", current: "1"} }
      it "creates a competition" do
        expect do
          post admin_competitions_path, params: {competition: competition_params}
        end.to change(Competition, :count).by(1)
        expect(flash[:success]).to be_present
        competition = Competition.order(:id).last
        expect(competition.start_date.to_s).to eq competition_params[:start_date]
        expect(competition.end_date.to_s).to eq "2026-04-30"
        expect(competition.current).to be_truthy
        expect(competition.display_name).to eq "MIBM 2026"
      end
    end
  end
end
