require "rails_helper"

RSpec.describe "Admin::EmailLogs" do
  let(:admin) { create(:user, :admin) }
  let(:regular_user) { create(:user, :tourist) }
  let!(:email_logs) { create_list(:email_log, 30) }

  describe "GET /admin/email_logs" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get admin_email_logs_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated but not an admin" do
      before { sign_in regular_user }

      it "raises authorization error", :raise_exceptions do
        expect do
          get admin_email_logs_path
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is an admin" do
      before { sign_in admin }

      it "returns http success" do
        get admin_email_logs_path
        expect(response).to have_http_status(:success)
      end

      it "paginates email logs with 25 per page" do
        get admin_email_logs_path
        # Count how many unique email recipients appear in the response
        email_count = email_logs.count { |log| response.body.include?(log.recipient) }
        expect(email_count).to eq(25)
      end

      it "orders email logs by created_at descending" do
        get admin_email_logs_path
        # The most recently created logs should appear in the response
        # Check that newer logs appear before older logs in the HTML
        oldest_log = email_logs.min_by(&:created_at)
        newest_log = email_logs.max_by(&:created_at)
        newest_position = response.body.index(newest_log.recipient)
        oldest_position = response.body.index(oldest_log.recipient)
        expect(newest_position).to be < oldest_position if oldest_position
      end

      it "supports pagination" do
        get admin_email_logs_path, params: { page: 2 }
        expect(response).to have_http_status(:success)
        # Page 2 should show the remaining 5 logs (30 total - 25 on page 1 = 5 on page 2)
        email_count = email_logs.count { |log| response.body.include?(log.recipient) }
        expect(email_count).to eq(5)
      end
    end
  end
end
