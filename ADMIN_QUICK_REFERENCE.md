# Admin System Quick Reference

## Authorization Hierarchy

```
Public User
├── Not Authenticated
│   └── Limited public access (home, tour listings, guide profiles)
│
├── Tourist (Authenticated)
│   ├── Create bookings
│   ├── View own bookings
│   ├── Leave reviews on completed tours
│   ├── View guide profiles and comments
│   └── Cannot access /admin
│
├── Guide (Authenticated)
│   ├── View own tours
│   ├── Manage own tours
│   ├── View own guide profile
│   ├── Manage own add-ons for tours
│   ├── View bookings for own tours
│   └── Cannot access /admin
│
└── Admin (Authenticated)
    └── /admin/* - Full system access
        ├── Manage all users
        ├── Manage all tours
        ├── Manage all bookings
        ├── Review all reviews
        ├── Manage guide profiles
        ├── View weather snapshots
        ├── View email logs
        └── Dashboard/metrics
```

## Role-Based Access Matrix

| Resource | Tourist | Guide | Admin |
|----------|---------|-------|-------|
| **Users** | View self | View self | Full CRUD |
| **Tours** | Browse all | Manage own | Manage all |
| **Bookings** | Create/manage own | View own tours | Manage all |
| **Reviews** | Create own* | Cannot create | Delete any |
| **Guide Profiles** | View public | Manage own | Manage all |
| **Tour Add-ons** | View active | Manage own | Manage all |
| **Comments** | Create on public profiles | Cannot create | Delete any |
| **Weather Data** | N/A | N/A | View |
| **Email Logs** | N/A | N/A | View |

*Tourists can only review completed tours they participated in

## Admin Panel Navigation

```
Admin Dashboard (/admin/metrics)
├── Dashboard (metrics, stats, recent bookings)
├── Users (/admin/users)
│   ├── List (search, paginate)
│   ├── Create new user
│   ├── Edit user (modal)
│   └── Delete user
├── Tours (/admin/tours)
│   ├── List (filter by status/title, paginate)
│   ├── Create new tour
│   ├── Edit tour (inline)
│   ├── Delete tour
│   └── Manage add-ons (/admin/tours/:id/add-ons)
│       ├── List add-ons
│       ├── Create add-on
│       ├── Edit add-on (inline)
│       ├── Delete add-on
│       └── Reorder add-ons (drag-drop)
├── Bookings (/admin/bookings)
│   ├── List (filter by status, paginate)
│   ├── Edit booking status/notes (inline)
│   └── Delete booking
├── Reviews (/admin/reviews)
│   ├── List (read-only, paginate)
│   ├── View review
│   └── Delete inappropriate reviews
├── Guide Profiles (/admin/guide_profiles)
│   ├── List guide profiles
│   ├── View guide (with tours and comments)
│   └── Edit guide (inline)
├── Weather Snapshots (/admin/weather_snapshots)
│   └── List weather data (read-only)
└── Email Logs (/admin/email_logs)
    └── List emails sent (read-only)
```

## Controller Inheritance

```
ApplicationController
├── includes Pundit::Authorization
├── rescue_from Pundit::NotAuthorizedError
├── after_action :verify_authorized
└── after_action :verify_policy_scoped

└── Admin::BaseController
    ├── before_action :authenticate_user!
    ├── before_action :require_admin
    ├── layout "admin"
    ├── skip Pundit verification (handled by require_admin)
    └── rescue_from Pundit::NotAuthorizedError (raises directly)
    
    └── Admin::*Controller (Users, Tours, Bookings, etc.)
        ├── include InlineEditable (optional, for inline editing)
        ├── before_action :set_resource (specific resources)
        └── CRUD actions with Turbo Stream responses
```

## Inline Editing Components

### Flow

```
User Action (Click Edit)
    ↓
GET /admin/resource/:id/edit (Turbo Stream request)
    ↓
render_inline_edit_form
    ↓
Replace DOM element with edit form
    ↓
User submits form
    ↓
PATCH /admin/resource/:id (Turbo Stream request)
    ↓
Update succeeds?
├─ YES → render_inline_update_success
│        ├─ Replace form with display view
│        ├─ Append success notification
│        └─ Return turbo_stream
│
└─ NO  → render_inline_update_failure
         ├─ Re-render form with errors
         └─ Return unprocessable_entity status
```

### Available Methods

| Method | Purpose |
|--------|---------|
| `render_inline_edit_form` | Show edit form in-page |
| `render_inline_update_success` | Replace with display + notification |
| `render_inline_update_failure` | Redisplay form with errors |
| `render_inline_delete_success` | Remove element + notification |
| `render_context_aware_inline_form` | Choose form based on referer |
| `render_context_aware_update_success` | Display based on context |

### Current Usage

- **Tours**: Used in admin tours index and guide profiles
- **Bookings**: Used for status/notes updates
- **Guide Profiles**: Used for bio/certs/languages updates
- **Tour Add-ons**: Full CRUD with inline editing

## Pundit Policy Structure

### Base Patterns

```ruby
# Admin-only resource
class SomePolicy < ApplicationPolicy
  def index?
    user.admin?
  end
  
  def update?
    user.admin?
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      user.admin? ? scope.all : scope.none
    end
  end
end
```

```ruby
# Owner + Admin
class SomePolicy < ApplicationPolicy
  def update?
    user.admin? || (record.owner == user)
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      user.admin? ? scope.all : scope.where(owner: user)
    end
  end
end
```

```ruby
# Role-specific + Admin
class SomePolicy < ApplicationPolicy
  def update?
    user.admin? || (user.guide? && record.tour.guide == user)
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      elsif user.guide?
        scope.joins(:tour).where(tours: { guide: user })
      else
        scope.where(user: user)
      end
    end
  end
end
```

## Turbo Stream Response Types

### In Admin Controllers

```ruby
# Success with notification
render turbo_stream: [
  turbo_stream.replace(dom_id(resource), partial: "display"),
  turbo_stream.append("notifications", partial: "notification", ...)
]

# Inline edit
render turbo_stream: turbo_stream.replace(
  dom_id(resource),
  partial: "edit_form"
)

# Delete with notification
render turbo_stream: [
  turbo_stream.remove(dom_id(resource)),
  turbo_stream.append("notifications", partial: "notification", ...)
]

# Modal update
render turbo_stream: turbo_stream.update("modal", "")
```

## Key File Paths

### Controllers (9 total)
```
app/controllers/admin/
├── base_controller.rb          (inheritance, auth check)
├── bookings_controller.rb      (CRUD + inline edit)
├── email_logs_controller.rb    (read-only)
├── guide_profiles_controller.rb (inline edit)
├── reviews_controller.rb       (read-only + delete)
├── tour_add_ons_controller.rb  (full CRUD, Pundit checks)
├── tours_controller.rb         (CRUD + inline edit)
├── users_controller.rb         (CRUD + broadcasts)
├── weather_snapshots_controller.rb (read-only)
app/
└── admin_controller.rb         (dashboard/metrics)
```

### Policies (12 total)
```
app/policies/
├── application_policy.rb       (defaults: all true)
├── booking_policy.rb           (complex scoping)
├── booking_add_on_policy.rb    (nested auth)
├── comment_policy.rb           (owner + admin)
├── email_log_policy.rb         (likely admin-only)
├── example_policy.rb           (template)
├── guide_profile_policy.rb     (guide + admin)
├── history_policy.rb           (user-specific)
├── review_policy.rb            (conditional create)
├── tour_policy.rb              (guide + admin + public)
├── tour_add_on_policy.rb       (tiered access)
└── user_policy.rb              (restrictive)
```

### Views
```
app/views/
├── admin/
│   ├── bookings/
│   │   ├── _booking.html.erb
│   │   ├── _booking_edit_form.html.erb
│   │   ├── edit.html.erb
│   │   └── index.html.erb
│   ├── email_logs/
│   │   └── index.html.erb
│   ├── guide_profiles/
│   │   ├── _profile_section.html.erb
│   │   ├── _tour_edit_form.html.erb
│   │   ├── _tour_row.html.erb
│   │   ├── edit.html.erb
│   │   ├── index.html.erb
│   │   └── show.html.erb
│   ├── reviews/
│   │   └── index.html.erb
│   ├── shared/
│   │   ├── _header.html.erb
│   │   ├── _notification.html.erb
│   │   └── _sidebar.html.erb
│   ├── tour_add_ons/
│   │   ├── _edit_form.html.erb
│   │   ├── _form.html.erb
│   │   ├── _tour_add_on.html.erb
│   │   └── index.html.erb
│   ├── tours/
│   │   ├── _tour.html.erb
│   │   ├── _tour_edit_form.html.erb
│   │   ├── edit.html.erb
│   │   ├── index.html.erb
│   │   └── new.html.erb (likely)
│   ├── users/
│   │   ├── _form.html.erb (likely)
│   │   ├── _user.html.erb
│   │   ├── edit.html.erb
│   │   ├── index.html.erb
│   │   ├── new.html.erb
│   │   └── show.html.erb
│   ├── weather_snapshots/
│   │   └── index.html.erb
│   └── metrics.html.erb (dashboard)
├── layouts/
│   └── admin.html.erb (main admin layout)
└── [other views for public pages]
```

## Real-Time Features

### Broadcasts to Admins

When a **new user** is created:
```
User#create_commit
└─ broadcast_created_to_admin
   └─ broadcast_prepend_to "admin_users_#{admin.id}"
      └─ Prepends user row to admin's user table
```

When a **user is updated**:
```
User#update_commit
└─ broadcast_updated_to_admin
   └─ broadcast_replace_to "admin_users_#{admin.id}"
      └─ Replaces user row in admin's user table
```

### Subscription

In admin layout:
```erb
<%= turbo_stream_from "admin_notifications_#{current_user.id}" %>
```

Allows any part of the app to broadcast to specific admin user:
```ruby
broadcast_append_to "admin_notifications_#{admin.id}", partial: "notification", ...
```

## Security Features

### Implemented
- Authentication required (Devise)
- Admin role check (`require_admin`)
- Pundit policies for fine-grained control
- CSRF protection (automatic with Turbo)
- Strong parameters (explicit expectations)
- 404 response for unauthorized access (not info leak)

### Missing/Could Improve
- Granular admin permissions (e.g., ReviewMod, ContentMod roles)
- Audit logging of admin actions
- Admin activity timeline
- Soft deletes/archive instead of hard delete
- Version history/change tracking
- Two-factor authentication for admins
- IP whitelisting for admin access
- Rate limiting on admin actions

## Database Indexing

The `users` table has:
- Unique index on `email`
- Unique index on `reset_password_token`
- Unique index on `unlock_token`
- Index on `role` (for filtering by role)

Recommended additional indexes:
- `(guide_id, created_at)` on tours (for guide's tours ordered by date)
- `(status, created_at)` on tours (for status filtering)
- `(status, created_at)` on bookings (for status filtering)
- `(user_id, created_at)` on bookings (for user's bookings)

## Common Code Patterns

### Admin CRUD with Turbo Streams
```ruby
def create
  @resource = Model.new(params)
  if @resource.save
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.prepend("table_body", partial: "resource", ...),
          turbo_stream.append("notifications", partial: "notification", ...),
          turbo_stream.update("modal", "")
        ]
      end
    end
  else
    render :new, status: :unprocessable_entity
  end
end

def destroy
  @resource.destroy
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.remove(dom_id(@resource)),
        turbo_stream.append("notifications", partial: "notification", ...)
      ]
    end
  end
end
```

### Inline Edit Pattern
```ruby
def edit
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        dom_id(@resource),
        partial: "edit_form"
      )
    end
  end
end

def update
  if @resource.update(params)
    render_inline_update_success(
      @resource,
      display_partial: "display",
      message: "Updated successfully"
    )
  else
    render_inline_update_failure(
      @resource,
      partial: "edit_form"
    )
  end
end
```

## Testing Considerations

### Model Tests
- Validate role enum
- Test broadcast methods
- Test associations

### Policy Tests
- Test each action for each role
- Test scope resolution for each role

### Controller Tests
- Test admin-only access
- Test CRUD operations
- Test Turbo Stream responses
- Test error handling

### System/Feature Tests
- Test full admin workflows
- Test inline editing
- Test notifications
- Test navigation
- Test access control
