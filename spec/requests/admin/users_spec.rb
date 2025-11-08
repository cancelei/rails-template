require "rails_helper"

RSpec.describe "Admin::Users" do
  let(:admin) { create(:user, :admin) }
  let(:tourist) { create(:user, :tourist) }
  let!(:test_user) { create(:user, :tourist, name: "Test User", email: "test@example.com") }

  describe "GET /admin/users" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get admin_users_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is not an admin" do
      before { sign_in tourist }

      it "raises authorization error", :raise_exceptions do
        expect do
          get admin_users_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is an admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end

      it "displays users" do
        get admin_users_path
        expect(assigns(:users)).to include(test_user)
      end

      it "paginates users" do
        create_list(:user, 30, :tourist)
        get admin_users_path
        expect(assigns(:users).count).to eq(25)
      end

      it "searches users by name" do
        get admin_users_path, params: { q: "Test User" }
        expect(assigns(:users)).to include(test_user)
      end

      it "searches users by email" do
        get admin_users_path, params: { q: "test@example" }
        expect(assigns(:users)).to include(test_user)
      end
    end
  end

  describe "GET /admin/users/:id" do
    before { sign_in admin }

    it "returns http success" do
      get admin_user_path(test_user)
      expect(response).to have_http_status(:success)
    end

    it "displays user details" do
      get admin_user_path(test_user)
      expect(response.body).to include(test_user.name)
      expect(response.body).to include(test_user.email)
    end
  end

  describe "GET /admin/users/new" do
    before { sign_in admin }

    it "returns http success" do
      get new_admin_user_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/users" do
    before { sign_in admin }

    context "with valid parameters" do
      let(:valid_params) do
        {
          user: {
            name: "New User",
            email: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123",
            role: "tourist"
          }
        }
      end

      it "creates a new user" do
        expect do
          post admin_users_path, params: valid_params
        end.to change(User, :count).by(1)
      end

      it "redirects to users index" do
        post admin_users_path, params: valid_params
        expect(response).to redirect_to(admin_users_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          user: {
            name: "",
            email: "invalid"
          }
        }
      end

      it "does not create a user" do
        expect do
          post admin_users_path, params: invalid_params
        end.not_to change(User, :count)
      end

      it "renders new template" do
        post admin_users_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    before { sign_in admin }

    it "returns http success" do
      get edit_admin_user_path(test_user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/users/:id" do
    before { sign_in admin }

    context "with valid parameters" do
      it "updates the user" do
        patch admin_user_path(test_user), params: { user: { name: "Updated Name" } }
        expect(test_user.reload.name).to eq("Updated Name")
      end

      it "redirects to users index" do
        patch admin_user_path(test_user), params: { user: { name: "Updated" } }
        expect(response).to redirect_to(admin_users_path)
      end

      it "can update user role" do
        patch admin_user_path(test_user), params: { user: { role: "guide" } }
        expect(test_user.reload.role).to eq("guide")
      end
    end

    context "with invalid parameters" do
      it "does not update the user" do
        original_name = test_user.name
        patch admin_user_path(test_user), params: { user: { name: "" } }
        expect(test_user.reload.name).to eq(original_name)
      end

      it "renders edit template" do
        patch admin_user_path(test_user), params: { user: { email: "invalid" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/users/:id" do
    before { sign_in admin }

    it "deletes the user" do
      user_to_delete = create(:user, :tourist)
      expect do
        delete admin_user_path(user_to_delete)
      end.to change(User, :count).by(-1)
    end

    it "redirects to users index" do
      delete admin_user_path(test_user)
      expect(response).to redirect_to(admin_users_path)
    end
  end
end
