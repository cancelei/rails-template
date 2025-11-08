# frozen_string_literal: true

# Helper methods for management interfaces (Admin and Guide)
# Provides role-aware helpers for permissions, context, and UI rendering
module ManagementHelper
  # Determines the current management context based on controller namespace
  # @return [Symbol] :admin, :guide, or :tourist
  def management_context
    return @management_context if defined?(@management_context)

    @management_context = if controller_path.start_with?("admin/")
                            :admin
                          elsif controller_path.start_with?("guides/")
                            :guide
                          else
                            :tourist
                          end
  end

  # Checks if current user is in admin context
  # @return [Boolean]
  def admin_context?
    management_context == :admin
  end

  # Checks if current user is in guide context
  # @return [Boolean]
  def guide_context?
    management_context == :guide
  end

  # Checks if current user can edit a resource based on Pundit policy
  # @param resource [ActiveRecord::Base] The resource to check
  # @return [Boolean]
  def current_user_can_edit?(resource)
    return false unless current_user

    Pundit.policy(current_user, resource).update?
  rescue Pundit::NotDefinedError
    false
  end

  # Checks if current user can delete a resource based on Pundit policy
  # @param resource [ActiveRecord::Base] The resource to check
  # @return [Boolean]
  def current_user_can_delete?(resource)
    return false unless current_user

    Pundit.policy(current_user, resource).destroy?
  rescue Pundit::NotDefinedError
    false
  end

  # Checks if current user can view a resource based on Pundit policy
  # @param resource [ActiveRecord::Base] The resource to check
  # @return [Boolean]
  def current_user_can_view?(resource)
    return false unless current_user

    Pundit.policy(current_user, resource).show?
  rescue Pundit::NotDefinedError
    false
  end

  # Returns the appropriate path for a resource based on context
  # @param resource [ActiveRecord::Base] The resource
  # @param action [Symbol] :show, :edit, :index, etc.
  # @return [String] The URL path
  def context_path_for(resource, action: :show)
    resource_name = resource.model_name.param_key

    case management_context
    when :admin
      send("#{action}_admin_#{resource_name}_path", resource)
    when :guide
      # Guides typically access their own resources through different routes
      if action == :edit
        send("edit_#{resource_name}_path", resource)
      else
        send("#{resource_name}_path", resource)
      end
    else
      send("#{resource_name}_path", resource)
    end
  rescue NoMethodError
    # Fallback to standard RESTful path
    send("#{resource_name}_path", resource)
  end

  # Returns CSS classes for status badges based on status value
  # @param status [String, Symbol] The status value
  # @return [String] CSS classes
  def status_badge_classes(status)
    base_classes = "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"

    status_classes = case status.to_s.downcase
                     when "confirmed", "scheduled", "active", "published"
                       "bg-success/10 text-success"
                     when "cancelled", "inactive", "archived"
                       "bg-danger/10 text-danger"
                     when "pending", "ongoing", "draft"
                       "bg-warning/10 text-warning"
                     when "done", "completed"
                       "bg-info/10 text-info"
                     else
                       "bg-muted text-muted-foreground"
                     end

    "#{base_classes} #{status_classes}"
  end

  # Formats a status for display (titleizes and humanizes)
  # @param status [String, Symbol] The status value
  # @return [String] Formatted status
  def format_status(status)
    status.to_s.titleize
  end

  # Returns the appropriate turbo frame ID for inline editing
  # @param resource [ActiveRecord::Base] The resource
  # @return [String] Turbo frame ID
  def inline_edit_frame_id(resource)
    dom_id(resource)
  end

  # Returns context-aware button classes
  # @param variant [Symbol] :primary, :secondary, :danger
  # @return [String] CSS classes
  def management_button_classes(variant: :primary)
    base_classes = "inline-flex items-center justify-center px-4 py-2 text-sm font-medium rounded-md " \
                   "transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2"

    variant_classes = case variant
                      when :primary
                        "bg-primary text-primary-foreground hover:bg-primary/90 focus:ring-primary"
                      when :secondary
                        "bg-secondary text-secondary-foreground hover:bg-secondary/80 focus:ring-secondary"
                      when :danger
                        "bg-danger text-white hover:bg-danger/90 focus:ring-danger"
                      when :ghost
                        "bg-transparent text-foreground hover:bg-muted focus:ring-muted"
                      else
                        "bg-muted text-muted-foreground hover:bg-muted/80 focus:ring-muted"
                      end

    "#{base_classes} #{variant_classes}"
  end

  # Checks if a record belongs to the current user
  # @param resource [ActiveRecord::Base] The resource
  # @return [Boolean]
  def owned_by_current_user?(resource)
    return false unless current_user

    # Check various ownership patterns
    if resource.respond_to?(:user)
      resource.user == current_user
    elsif resource.respond_to?(:guide)
      resource.guide == current_user
    elsif resource.respond_to?(:user_id)
      resource.user_id == current_user.id
    elsif resource.respond_to?(:guide_id)
      resource.guide_id == current_user.id
    else
      false
    end
  end

  # Returns a context-aware notification message
  # @param action [Symbol] :created, :updated, :deleted
  # @param resource_name [String] The resource type name
  # @return [String] Notification message
  def management_notification_message(action, resource_name)
    role_prefix = admin_context? ? "Admin" : "You"

    case action
    when :created
      "#{role_prefix} created #{resource_name} successfully"
    when :updated
      "#{role_prefix} updated #{resource_name} successfully"
    when :deleted
      "#{role_prefix} deleted #{resource_name}"
    else
      "#{role_prefix} #{action} #{resource_name}"
    end
  end

  # Renders appropriate empty state message based on context
  # @param resource_name [String] The resource type (plural)
  # @return [String] Empty state message
  def empty_state_message(resource_name)
    if guide_context?
      "You don't have any #{resource_name} yet"
    elsif admin_context?
      "No #{resource_name} found"
    else
      "No #{resource_name} available"
    end
  end

  # Determines if advanced fields should be shown (admin gets more fields)
  # @return [Boolean]
  def show_advanced_fields?
    admin_context?
  end
end
