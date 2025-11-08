module Admin
  class TourAddOnsController < Admin::BaseController
    before_action :set_tour
    before_action :set_tour_add_on, only: %i[edit update destroy]

    def index
      @tour_add_ons = @tour.tour_add_ons.by_position
      @tour_add_on = TourAddOn.new
    end

    def new
      @tour_add_on = @tour.tour_add_ons.build
    end

    def edit
      authorize @tour_add_on

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(@tour_add_on),
            partial: "admin/tour_add_ons/edit_form",
            locals: { tour: @tour, tour_add_on: @tour_add_on }
          )
        end
        format.html
      end
    end

    def create
      @tour_add_on = @tour.tour_add_ons.build(tour_add_on_params)
      authorize @tour_add_on

      if @tour_add_on.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.append("tour_add_ons_list", partial: "admin/tour_add_ons/tour_add_on",
                                                       locals: { tour_add_on: @tour_add_on, tour: @tour }),
              turbo_stream.append("notifications", partial: "admin/shared/notification",
                                                   locals: { message: "Add-on created successfully", type: "success" }),
              turbo_stream.replace("tour_add_on_form", partial: "admin/tour_add_ons/form",
                                                       locals: { tour: @tour, tour_add_on: TourAddOn.new })
            ]
          end
          format.html { redirect_to admin_tour_tour_add_ons_path(@tour), notice: "Add-on was successfully created." }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "tour_add_on_form",
              partial: "admin/tour_add_ons/form",
              locals: { tour: @tour, tour_add_on: @tour_add_on }
            ), status: :unprocessable_entity
          end
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def update
      authorize @tour_add_on

      if @tour_add_on.update(tour_add_on_params)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace(dom_id(@tour_add_on), partial: "admin/tour_add_ons/tour_add_on",
                                                         locals: { tour_add_on: @tour_add_on, tour: @tour }),
              turbo_stream.append("notifications", partial: "admin/shared/notification",
                                                   locals: { message: "Add-on updated successfully", type: "success" })
            ]
          end
          format.html { redirect_to admin_tour_tour_add_ons_path(@tour), notice: "Add-on was successfully updated." }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              dom_id(@tour_add_on),
              partial: "admin/tour_add_ons/edit_form",
              locals: { tour: @tour, tour_add_on: @tour_add_on }
            ), status: :unprocessable_entity
          end
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      authorize @tour_add_on

      if @tour_add_on.destroy
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.remove(dom_id(@tour_add_on)),
              turbo_stream.append("notifications", partial: "admin/shared/notification",
                                                   locals: { message: "Add-on deleted successfully", type: "success" })
            ]
          end
          format.html { redirect_to admin_tour_tour_add_ons_path(@tour), notice: "Add-on was successfully deleted." }
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(
              "notifications",
              partial: "admin/shared/notification",
              locals: { message: "Failed to delete add-on: #{@tour_add_on.errors.full_messages.join(", ")}",
                        type: "error" }
            )
          end
          format.html { redirect_to admin_tour_tour_add_ons_path(@tour), alert: "Failed to delete add-on." }
        end
      end
    end

    def reorder
      params[:positions].each do |id, position|
        tour_add_on = @tour.tour_add_ons.find(id)
        authorize tour_add_on, :reorder?
        tour_add_on.update(position:)
      end

      head :ok
    end

    private

    def set_tour
      @tour = Tour.find(params[:tour_id])
    end

    def set_tour_add_on
      @tour_add_on = @tour.tour_add_ons.find(params[:id])
    end

    def tour_add_on_params
      params.expect(
        tour_add_on: %i[name
                        description
                        addon_type
                        price_cents
                        currency
                        pricing_type
                        maximum_quantity
                        active
                        position]
      )
    end
  end
end
