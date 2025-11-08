# frozen_string_literal: true

# Provides inline editing capabilities using Turbo Streams
# Include this concern in controllers that support inline editing
#
# Example usage:
#   class ToursController < ApplicationController
#     include InlineEditable
#
#     def edit
#       render_inline_edit_form(@tour, partial: "guides/dashboard/tour_edit_form")
#     end
#
#     def update
#       if @tour.update(tour_params)
#         render_inline_update_success(
#           @tour,
#           display_partial: "guides/dashboard/tour_card",
#           message: "Tour updated successfully"
#         )
#       else
#         render_inline_update_failure(@tour, partial: "guides/dashboard/tour_edit_form")
#       end
#     end
#   end
module InlineEditable
  extend ActiveSupport::Concern

  # Renders an edit form for inline editing via Turbo Stream
  # Falls back to regular HTML format if not a Turbo Stream request
  #
  # @param resource [ActiveRecord::Base] The record to edit
  # @param partial [String] Path to the edit form partial
  # @param locals [Hash] Additional local variables for the partial
  def render_inline_edit_form(resource, partial:, locals: {})
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(resource),
          partial:,
          locals: { resource.model_name.param_key.to_sym => resource }.merge(locals)
        )
      end
      format.html # Regular edit page
    end
  end

  # Renders success response for inline update
  # Replaces the record's DOM element with display partial and shows notification
  #
  # @param resource [ActiveRecord::Base] The updated record
  # @param display_partial [String] Path to the display partial (card/row view)
  # @param message [String] Success message to display
  # @param additional_streams [Array<Turbo::Streams::TagBuilder>] Additional turbo streams to include
  # @param locals [Hash] Additional local variables for the partial
  def render_inline_update_success(resource, display_partial:, message:, additional_streams: [], locals: {})
    respond_to do |format|
      format.turbo_stream do
        streams = [
          turbo_stream.replace(
            dom_id(resource),
            partial: display_partial,
            locals: { resource.model_name.param_key.to_sym => resource }.merge(locals)
          ),
          turbo_stream.append(
            "notifications",
            partial: notification_partial_path,
            locals: { message:, type: "success" }
          )
        ] + additional_streams

        render turbo_stream: streams
      end
      format.html { redirect_to resource, notice: message }
    end
  end

  # Renders failure response for inline update
  # Re-renders the edit form with validation errors
  #
  # @param resource [ActiveRecord::Base] The record with errors
  # @param partial [String] Path to the edit form partial
  # @param locals [Hash] Additional local variables for the partial
  def render_inline_update_failure(resource, partial:, locals: {})
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(resource),
          partial:,
          locals: { resource.model_name.param_key.to_sym => resource }.merge(locals)
        ), status: :unprocessable_entity
      end
      format.html { render :edit, status: :unprocessable_entity }
    end
  end

  # Renders success response for inline deletion
  # Removes the record's DOM element and shows notification
  #
  # @param resource [ActiveRecord::Base] The deleted record
  # @param message [String] Success message to display
  # @param redirect_path [String] Path to redirect to for HTML format
  def render_inline_delete_success(resource, message:, redirect_path:)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(resource)),
          turbo_stream.append(
            "notifications",
            partial: notification_partial_path,
            locals: { message:, type: "info" }
          )
        ]
      end
      format.html { redirect_to redirect_path, notice: message }
    end
  end

  # Renders a context-aware partial based on request referer
  # Useful when the same resource can be edited from multiple pages
  #
  # @param resource [ActiveRecord::Base] The record to edit/display
  # @param context_mapping [Hash] Maps referer keywords to partial paths
  # @param default_partial [String] Default partial if no context matches
  # @param action [Symbol] :edit or :display
  #
  # Example:
  #   render_context_aware_inline_form(
  #     @tour,
  #     context_mapping: {
  #       "guide_profiles" => "admin/guide_profiles/tour",
  #       "dashboard" => "guides/dashboard/tour"
  #     },
  #     default_partial: "admin/tours/tour",
  #     action: :edit  # Will append "_edit_form" to the partial name
  #   )
  def render_context_aware_inline_form(resource, context_mapping:, default_partial:, action:)
    partial_suffix = action == :edit ? "_edit_form" : ""
    selected_partial = default_partial

    # Check referer to determine context
    context_mapping.each do |keyword, partial_path|
      if request.referer&.include?(keyword)
        selected_partial = partial_path
        break
      end
    end

    partial_with_suffix = "#{selected_partial}#{partial_suffix}"

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          dom_id(resource),
          partial: partial_with_suffix,
          locals: { resource.model_name.param_key.to_sym => resource }
        )
      end
      format.html
    end
  end

  # Renders context-aware update success with different partials based on location
  #
  # @param resource [ActiveRecord::Base] The updated record
  # @param context_mapping [Hash] Maps referer keywords to display partial paths
  # @param default_partial [String] Default display partial
  # @param message [String] Success message
  def render_context_aware_update_success(resource, context_mapping:, default_partial:, message:)
    selected_partial = default_partial

    # Check referer to determine context
    context_mapping.each do |keyword, partial_path|
      if request.referer&.include?(keyword)
        selected_partial = partial_path
        break
      end
    end

    render_inline_update_success(resource, display_partial: selected_partial, message:)
  end

  private

  # Determines the correct notification partial path
  # Admin controllers use admin notification partial, others use shared
  def notification_partial_path
    if controller_path.start_with?("admin/")
      "admin/shared/notification"
    else
      "shared/notification"
    end
  end
end
