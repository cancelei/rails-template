module Admin
  class UsersController < Admin::BaseController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = User.order(created_at: :desc)
      if params[:q].present?
        @users = @users.where("name ILIKE ? OR email ILIKE ?", "%#{params[:q]}%",
                              "%#{params[:q]}%")
      end
      @users = @users.page(params[:page]).per(25)
    end

    def show
    end

    def new
      @user = User.new
    end

    def edit
    end

    def create
      @user = User.new(user_params)

      if @user.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.prepend("users_table_body",
                                   partial: "admin/users/user",
                                   locals: { user: @user }),
              turbo_stream.append("notifications",
                                  partial: "admin/shared/notification",
                                  locals: { message: "User created successfully", type: "success" }),
              turbo_stream.update("modal", "")
            ]
          end
          format.html { redirect_to admin_users_path, notice: "User was successfully created." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @user.update(user_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(dom_id(@user),
                                   partial: "admin/users/user",
                                   locals: { user: @user }),
              turbo_stream.append("notifications",
                                  partial: "admin/shared/notification",
                                  locals: { message: "User updated successfully", type: "success" }),
              turbo_stream.update("modal", "")
            ]
          end
          format.html { redirect_to admin_users_path, notice: "User was successfully updated." }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(dom_id(@user)),
            turbo_stream.append("notifications",
                                partial: "admin/shared/notification",
                                locals: { message: "User deleted", type: "info" })
          ]
        end
        format.html { redirect_to admin_users_path, notice: "User was successfully deleted." }
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.expect(user: %i[name email role phone password password_confirmation])
    end
  end
end
