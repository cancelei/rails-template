module Admin
  class EmailLogsController < Admin::BaseController
    def index
      @email_logs = EmailLog.order(created_at: :desc).page(params[:page]).per(25)
    end
  end
end
