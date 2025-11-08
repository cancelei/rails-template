module ApplicationHelper
  # Returns a list of hashes describing the primary navigation links.
  # Each hash includes the label, path, and aria label so that views can render
  # the links using their own presentation needs (desktop vs mobile).
  def primary_navigation_links(current_user)
    links = [
      build_nav_link("Home", root_path, "Go to home page")
    ]

    if current_user&.tourist?
      links << build_nav_link(
        "History",
        history_path,
        "View your travel history"
      )
    end

    links
  end

  # Returns display data for the authentication section of the navigation.
  # When signed in we expose the email and sign-out details; otherwise we return
  # the set of links that should be rendered.
  def auth_navigation_data(current_user)
    if current_user
      {
        state: :signed_in,
        email: current_user.email,
        sign_out: {
          label: "Sign Out",
          path: destroy_user_session_path,
          method: :delete,
          aria_label: "Sign out of your account"
        }
      }
    else
      {
        state: :signed_out,
        links: [
          build_nav_link(
            "Sign In",
            new_user_session_path,
            "Sign in to your account"
          ),
          build_nav_link(
            "Become a Guide",
            become_a_guide_path,
            "Become a tour guide"
          ),
          build_nav_link(
            "Sign Up",
            new_tourist_registration_path,
            "Create a new account"
          )
        ]
      }
    end
  end

  # Admin permission helpers

  # Check if current user can edit a resource
  # Uses Pundit policy to determine permission
  #
  # @param resource [ActiveRecord::Base] The resource to check
  # @return [Boolean] true if current user can edit the resource
  def can_edit?(resource)
    return false unless current_user && resource

    policy(resource).edit?
  rescue Pundit::NotDefinedError
    false
  end

  # Check if current user can manage (edit, update, destroy) a resource
  # Uses Pundit policy to determine permission
  #
  # @param resource [ActiveRecord::Base] The resource to check
  # @return [Boolean] true if current user can manage the resource
  def can_manage?(resource)
    return false unless current_user && resource

    policy(resource).update? && policy(resource).destroy?
  rescue Pundit::NotDefinedError
    false
  end

  # Check if current user is an admin
  #
  # @return [Boolean] true if current user has admin role
  def admin?
    current_user&.admin?
  end

  # Check if current user is a guide
  #
  # @return [Boolean] true if current user has guide role
  def guide?
    current_user&.guide?
  end

  # Check if current user is a tourist
  #
  # @return [Boolean] true if current user has tourist role
  def tourist?
    current_user&.tourist?
  end

  # Render admin edit button if user has permission
  # Returns an edit button that triggers inline editing via Turbo
  #
  # @param resource [ActiveRecord::Base] The resource to edit
  # @param edit_path [String] The edit route path
  # @param options [Hash] Additional options for customization
  # @option options [String] :text Button text (default: "Edit")
  # @option options [String] :css_class Additional CSS classes
  # @option options [String] :icon_only Show only icon, no text
  # @return [String] HTML string for edit button or empty string
  def admin_edit_button(resource, edit_path, options = {})
    return "" unless can_edit?(resource)

    text = options.fetch(:text, "Edit")
    css_class = options.fetch(:css_class, "btn btn-sm btn-outline")
    icon_only = options.fetch(:icon_only, false)

    link_to edit_path,
            data: { turbo_frame: dom_id(resource), action: "click->inline-edit#edit" },
            class: css_class,
            title: text do
      content = <<~HTML.html_safe
        <svg class="w-4 h-4 #{"inline mr-1" unless icon_only}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
        </svg>
        #{icon_only ? "<span class=\"sr-only\">#{text}</span>" : text}
      HTML
      content
    end
  end

  # Show admin indicator badge
  # Displays a visual badge to indicate admin-editable content
  #
  # @param visible [Boolean] Whether to show the badge (default: true if admin)
  # @return [String] HTML string for admin badge or empty string
  def admin_indicator(visible: admin?)
    return "" unless visible

    content_tag :span,
                "Admin",
                class: "admin-edit-indicator",
                title: "This content can be edited by admins"
  end

  private

  def build_nav_link(label, path, aria_label)
    { label:, path:, aria_label: }
  end
end
