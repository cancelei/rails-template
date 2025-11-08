# Admin Inline Editing Guide

## Overview

This guide documents the inline editing system that allows administrators to edit any content directly in the public-facing views without navigating to separate admin pages. This unified UX approach makes the platform easier to manage, reuse, teach, and learn.

## Table of Contents

1. [Architecture](#architecture)
2. [Key Components](#key-components)
3. [Authorization System](#authorization-system)
4. [Usage Guide](#usage-guide)
5. [Adding Inline Editing to New Resources](#adding-inline-editing-to-new-resources)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Architecture

### Design Principles

1. **Unified UX**: Admins edit content directly in the same views as regular users
2. **Role-based Access**: Clear permission boundaries using Pundit policies
3. **Reusable Components**: Shared partials and helpers for consistent behavior
4. **Context-aware**: Forms adapt based on where they're triggered from
5. **Real-time Updates**: Turbo Streams for seamless editing without page reloads

### Technology Stack

- **Rails 8.0.2**: Backend framework
- **Turbo/Hotwire**: Real-time updates and inline editing
- **Stimulus JS**: Client-side behavior controllers
- **Pundit**: Authorization policies
- **Tailwind CSS**: Styling and visual indicators

---

## Key Components

### 1. Reusable Partials

#### `shared/_inline_editable_field.html.erb`

Single field inline editing with edit button on hover.

**Usage:**
```erb
<%= render "shared/inline_editable_field",
    resource: @tour,
    field_name: :title,
    display_value: @tour.title,
    policy: policy(@tour),
    edit_url: edit_tour_path(@tour),
    css_class: "text-2xl font-bold" %>
```

**Parameters:**
- `resource`: The ActiveRecord model
- `field_name`: Attribute name (for DOM ID)
- `display_value`: Current value to display
- `policy`: Pundit policy object
- `edit_url`: URL to trigger edit mode
- `css_class`: Additional CSS classes
- `wrapper_class`: Wrapper element classes
- `tag`: HTML tag for display (default: 'span')
- `show_edit_button`: Show/hide edit button (default: true if can edit)

#### `shared/_inline_editable_block.html.erb`

Block-level inline editing for entire sections.

**Usage:**
```erb
<%= render "shared/inline_editable_block",
    resource: @tour,
    policy: policy(@tour),
    edit_url: edit_tour_path(@tour),
    edit_button_text: "Edit Tour" do %>
  <h2><%= @tour.title %></h2>
  <p><%= @tour.description %></p>
<% end %>
```

**Parameters:**
- `resource`: The ActiveRecord model
- `policy`: Pundit policy object
- `edit_url`: URL to trigger edit mode
- `edit_button_text`: Button text (default: "Edit")
- `wrapper_class`: Wrapper element classes
- `button_position`: Position of edit button ("top-right", "top-left", "bottom-right", "bottom-left")
- `show_indicator`: Show visual indicator (default: true)

### 2. Helper Methods

Located in `app/helpers/application_helper.rb`:

#### Permission Checking

```ruby
# Check if current user can edit a resource
can_edit?(resource)

# Check if current user can manage (edit + destroy) a resource
can_manage?(resource)

# Role checkers
admin?
guide?
tourist?
```

#### Rendering Helpers

```ruby
# Render admin edit button if user has permission
admin_edit_button(resource, edit_path, options = {})

# Show admin indicator badge
admin_indicator(visible: admin?)
```

**Example:**
```erb
<%= admin_edit_button(@tour, edit_tour_path(@tour),
    text: "Edit Tour",
    icon_only: false) %>
```

### 3. Controller Concern

The `InlineEditable` concern (`app/controllers/concerns/inline_editable.rb`) provides methods for handling inline editing in controllers.

**Include in your controller:**
```ruby
class ToursController < ApplicationController
  include InlineEditable
end
```

**Available methods:**

```ruby
# Render edit form for inline editing
render_inline_edit_form(resource, partial:, locals: {})

# Render success response with notification
render_inline_update_success(resource, display_partial:, message:,
                            additional_streams: [], locals: {})

# Render failure response with form errors
render_inline_update_failure(resource, partial:, locals: {})

# Render success response for deletion
render_inline_delete_success(resource, message:, redirect_path:)

# Context-aware inline form rendering
render_context_aware_inline_form(resource, context_mapping:,
                                default_partial:, action:)

# Context-aware update success
render_context_aware_update_success(resource, context_mapping:,
                                   default_partial:, message:)
```

### 4. Stimulus Controller

The `inline_edit_controller.js` provides client-side behavior:

**Features:**
- Loading states during edits
- Keyboard shortcuts (Ctrl/Cmd + E to edit, ESC to cancel)
- Success flash animations
- Accessibility enhancements

**Usage:**
```html
<div data-controller="inline-edit"
     data-inline-edit-editable-value="true">
  <!-- Editable content -->
</div>
```

### 5. Pundit Policies

Enhanced base policy with role-based helpers (`app/policies/application_policy.rb`):

```ruby
# Role checkers
admin?
guide?
tourist?

# Ownership checkers
owner?          # User owns the record
record_guide?   # User is the guide for the record

# Permission methods
manage?         # Full CRUD access
can_edit?       # Edit permission
inline_edit?    # Inline editing permission
```

---

## Authorization System

### Permission Hierarchy

```
Admin
  ├─ Full access to all resources
  ├─ Can edit any tour, guide profile, booking, etc.
  └─ Can manage users and system settings

Guide
  ├─ Can edit own profile
  ├─ Can manage own tours
  ├─ Can view/manage bookings for their tours
  └─ Read-only access to other content

Tourist
  ├─ Can manage own bookings
  ├─ Can leave reviews on completed tours
  └─ Read-only access to tours and guide profiles

Guest (Not logged in)
  └─ Read-only access to public content
```

### Policy Examples

#### TourPolicy

```ruby
def update?
  admin? || record_guide?
end

def inline_edit?
  admin? || record_guide?
end
```

**Explanation:**
- Admins can edit ANY tour
- Guides can only edit THEIR tours
- Tourists cannot edit tours

#### GuideProfilePolicy

```ruby
def update?
  admin? || owner?
end

def inline_edit?
  admin? || owner?
end
```

**Explanation:**
- Admins can edit ANY guide profile
- Guides can only edit THEIR profile
- Tourists cannot edit guide profiles

---

## Usage Guide

### For Administrators

#### Editing Tours

1. Navigate to any tour page (e.g., `/tours/123`)
2. Hover over the "Tour Details" card
3. Click the "Edit" button that appears in the top-right corner
4. Edit the fields inline
5. Click "Save Changes" to update or "Cancel" to discard

**Keyboard Shortcut:** Hover over editable content and press `Ctrl+E` (or `Cmd+E` on Mac)

#### Editing Guide Profiles

1. Navigate to any guide profile page (e.g., `/guide_profiles/456`)
2. Hover over the profile information
3. Click the "Edit" button
4. Update bio, languages, or other fields
5. Save or cancel

#### Visual Indicators

When logged in as admin, editable content shows:
- Edit button on hover (desktop)
- Always-visible edit button (mobile)
- Blue border overlay on hover
- Optional "Admin" badge on editable sections

### For Developers

#### Adding Inline Editing to Tours (Example)

**Step 1: Include the concern in the controller**

```ruby
# app/controllers/tours_controller.rb
class ToursController < ApplicationController
  include InlineEditable

  before_action :set_tour, only: %i[edit update]
  before_action :authorize_tour, only: %i[edit update]

  def edit
    render_context_aware_inline_form(
      @tour,
      context_mapping: {
        "tours" => "tours/tour_details",
        "dashboard" => "guides/dashboard/tour"
      },
      default_partial: "guides/dashboard/tour",
      action: :edit
    )
  end

  def update
    if @tour.update(tour_params)
      render_context_aware_update_success(
        @tour,
        context_mapping: {
          "tours" => "tours/tour_details",
          "dashboard" => "guides/dashboard/tour_card"
        },
        default_partial: "guides/dashboard/tour_card",
        message: "Tour updated successfully"
      )
    else
      render_inline_update_failure(@tour,
        partial: "tours/tour_details_edit_form")
    end
  end
end
```

**Step 2: Create display partial**

```erb
<%# app/views/tours/_tour_details.html.erb %>
<div id="<%= dom_id(tour) %>" class="card">
  <div class="card-body">
    <div class="flex items-start justify-between mb-4">
      <h2 class="text-xl font-semibold">Tour Details</h2>
      <%= admin_edit_button(tour, edit_tour_path(tour)) if can_edit?(tour) %>
    </div>
    <!-- Display tour information -->
  </div>
</div>
```

**Step 3: Create edit form partial**

```erb
<%# app/views/tours/_tour_details_edit_form.html.erb %>
<div id="<%= dom_id(tour) %>" class="card">
  <div class="card-body">
    <%= form_with(model: tour, data: { turbo_frame: dom_id(tour) }) do |f| %>
      <!-- Form fields -->
      <%= f.submit "Save Changes", class: "btn btn-primary" %>
    <% end %>
  </div>
</div>
```

**Step 4: Update the view to use Turbo Frame**

```erb
<%# app/views/tours/show.html.erb %>
<%= turbo_frame_tag dom_id(@tour) do %>
  <%= render "tour_details", tour: @tour %>
<% end %>
```

**Step 5: Enhance the policy**

```ruby
# app/policies/tour_policy.rb
class TourPolicy < ApplicationPolicy
  def inline_edit?
    admin? || record_guide?
  end
end
```

---

## Adding Inline Editing to New Resources

Follow this checklist to add inline editing to a new resource:

### 1. Controller Setup

- [ ] Include `InlineEditable` concern
- [ ] Add `edit` and `update` actions
- [ ] Authorize actions with Pundit
- [ ] Use context-aware rendering if needed

### 2. Create Partials

- [ ] Create display partial (`_resource_display.html.erb`)
- [ ] Create edit form partial (`_resource_edit_form.html.erb`)
- [ ] Include DOM ID for Turbo Frame targeting
- [ ] Add edit button with proper authorization check

### 3. Update View

- [ ] Wrap content in `turbo_frame_tag`
- [ ] Render display partial inside frame
- [ ] Ensure unique DOM IDs

### 4. Update Policy

- [ ] Add `inline_edit?` method
- [ ] Define who can edit (admin? || owner?)
- [ ] Test authorization rules

### 5. Routes

- [ ] Add `edit` and `update` routes if not present
- [ ] Verify route accessibility

### 6. Styling

- [ ] Add hover effects for edit buttons
- [ ] Ensure responsive design
- [ ] Test on mobile devices

---

## Best Practices

### 1. Always Use Policies

Never check permissions directly in views or controllers. Always use Pundit policies:

❌ **Bad:**
```erb
<% if current_user&.admin? %>
  <%= link_to "Edit", edit_tour_path(@tour) %>
<% end %>
```

✅ **Good:**
```erb
<% if can_edit?(@tour) %>
  <%= admin_edit_button(@tour, edit_tour_path(@tour)) %>
<% end %>
```

### 2. Consistent Partial Naming

Follow these naming conventions:
- Display: `_resource_display.html.erb`
- Edit Form: `_resource_edit_form.html.erb`

### 3. Error Handling

Always show validation errors in edit forms:

```erb
<% if resource.errors.any? %>
  <div class="alert alert-error">
    <h3>Please fix the following errors:</h3>
    <ul>
      <% resource.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

### 4. Accessibility

- Use semantic HTML
- Include ARIA labels
- Support keyboard navigation
- Test with screen readers

### 5. Mobile Considerations

- Show edit buttons always on mobile (not just on hover)
- Ensure forms are touch-friendly
- Test on various screen sizes

### 6. Performance

- Use `includes` to avoid N+1 queries
- Load only necessary associations
- Consider caching for frequently accessed content

---

## Troubleshooting

### Edit button doesn't appear

**Possible causes:**
1. User doesn't have permission (check Pundit policy)
2. `can_edit?` helper not called correctly
3. CSS hiding the button (check responsive styles)

**Solution:**
```ruby
# In Rails console
user = User.find(admin_id)
tour = Tour.find(tour_id)
policy = TourPolicy.new(user, tour)
policy.edit? # Should return true for admins
```

### Form doesn't submit via Turbo

**Possible causes:**
1. Missing `data: { turbo_frame: dom_id(resource) }` on form
2. Turbo Frame ID mismatch
3. JavaScript errors

**Solution:**
Check browser console for errors and verify DOM IDs match:
```erb
<%= turbo_frame_tag dom_id(@tour) do %>
  <%= form_with model: @tour, data: { turbo_frame: dom_id(@tour) } do |f| %>
    ...
  <% end %>
<% end %>
```

### Updates don't persist

**Possible causes:**
1. Strong parameters not allowing the attribute
2. Validation failing silently
3. Database constraints

**Solution:**
Check logs and ensure strong parameters include the fields:
```ruby
def tour_params
  params.expect(tour: [:title, :description, ...])
end
```

### Context-aware rendering not working

**Possible causes:**
1. Referer not matching context keywords
2. Incorrect context mapping

**Solution:**
Debug the referer in controller:
```ruby
def edit
  Rails.logger.debug "Referer: #{request.referer}"
  # ...
end
```

---

## Summary

The inline editing system provides a seamless admin experience by:

1. ✅ **Unified UX**: Edit content in the same views as regular users
2. ✅ **Role-based**: Clear permissions via Pundit policies
3. ✅ **Reusable**: Shared components for consistency
4. ✅ **Context-aware**: Forms adapt to their location
5. ✅ **Extendable**: Easy to add to new resources

This approach makes the platform:
- **Easier to manage**: No separate admin interface to maintain
- **Easier to reuse**: Components work across different contexts
- **Easier to teach**: Consistent patterns throughout
- **Easier to learn**: Less cognitive load for developers

For questions or contributions, refer to the codebase documentation or open an issue.
