module AdminHelper
  def admin_page_title(title)
    content_for(:page_title, title)
  end

  def status_badge(status, type: :default)
    colors = case type
             when :booking
               booking_status_colors(status)
             when :tour
               tour_status_colors(status)
             when :user_role
               user_role_colors(status)
             else
               default_status_colors(status)
             end

    content_tag(:span, status.to_s.titleize,
                class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{colors}")
  end

  def admin_metric_card(title:, count:, color: "blue", _icon: nil)
    colors = {
      "blue" => "bg-blue-500",
      "green" => "bg-green-500",
      "purple" => "bg-purple-500",
      "orange" => "bg-orange-500",
      "red" => "bg-red-500",
      "indigo" => "bg-indigo-500"
    }

    content_tag(:div, class: "#{colors[color]} text-white p-6 rounded-lg shadow-md") do
      concat content_tag(:h2, title, class: "text-lg font-semibold mb-2")
      concat content_tag(:p, count, class: "text-3xl font-bold")
    end
  end

  def admin_action_button(text, path, options = {})
    default_options = {
      class: "inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm " \
             "font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 " \
             "focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
    }
    link_to text, path, default_options.merge(options)
  end

  def admin_delete_button(text, path, options = {})
    default_options = {
      method: :delete,
      form: { data: { turbo_confirm: "Are you sure?" } },
      class: "text-red-600 hover:text-red-900"
    }
    button_to text, path, default_options.merge(options)
  end

  private

  def booking_status_colors(status)
    case status.to_s
    when "pending"
      "bg-yellow-100 text-yellow-800"
    when "confirmed"
      "bg-blue-100 text-blue-800"
    when "completed"
      "bg-green-100 text-green-800"
    when "cancelled"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def tour_status_colors(status)
    case status.to_s
    when "scheduled"
      "bg-blue-100 text-blue-800"
    when "in_progress", "ongoing"
      "bg-yellow-100 text-yellow-800"
    when "completed", "done"
      "bg-green-100 text-green-800"
    when "cancelled"
      "bg-red-100 text-red-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def user_role_colors(role)
    case role.to_s
    when "admin"
      "bg-purple-100 text-purple-800"
    when "guide"
      "bg-blue-100 text-blue-800"
    when "tourist"
      "bg-green-100 text-green-800"
    else
      "bg-gray-100 text-gray-800"
    end
  end

  def default_status_colors(_status)
    "bg-gray-100 text-gray-800"
  end
end
