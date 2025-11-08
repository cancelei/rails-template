# Admin Implementation Analysis

## Overview

This Rails 8 application implements a comprehensive admin interface with role-based access control (RBAC), Pundit-based authorization policies, and Turbo Streams-powered inline editing capabilities. The admin system is completely isolated from the public application and manages users, tours, bookings, reviews, guide profiles, weather data, and email logs.

---

## 1. User Roles and Authorization Setup

### Role Implementation (app/models/user.rb)

The application uses a simple three-tier role system implemented as a Rails enum:

```ruby
enum :role, { tourist: "tourist", guide: "guide", admin: "admin" }
```

**Role Definitions:**
- **tourist**: Regular users who book tours and leave reviews
- **guide**: Users who create and manage tours, view their bookings and guide profiles
- **admin**: Full system access to manage all resources

**Key User Model Features:**
- Role validation: `validates :role, presence: true, inclusion: { in: roles.keys }`
- Role index in database for efficient filtering
- Automatic guide profile creation for new guides: `after_create :create_guide_profile_if_guide`
- Turbo Stream broadcasts for real-time admin updates:
  - `broadcast_created_to_admin` - notifies admins when new users are created
  - `broadcast_updated_to_admin` - notifies admins when users are updated

### Authorization Architecture

The application uses **Pundit** as its authorization library with the following setup:

**ApplicationController Integration:**
- `include Pundit::Authorization` - enables Pundit in controllers
- `rescue_from Pundit::NotAuthorizedError` - handles authorization failures
- `after_action :verify_authorized` - ensures authorization checks are performed (except for index actions)
- `after_action :verify_policy_scoped` - ensures index actions use scoped queries
- Unauthorized access raises `ActiveRecord::RecordNotFound` (secure approach that doesn't leak information)

---

## 2. Admin Access Control

### Admin Base Controller (app/controllers/admin/base_controller.rb)

All admin controllers inherit from `Admin::BaseController`:

```ruby
module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    layout "admin"
    
    # Admin controllers handle their own authorization
    skip_after_action :verify_authorized
    skip_after_action :verify_policy_scoped
    
    # Skip ApplicationController rescue_from for direct error handling
    rescue_from Pundit::NotAuthorizedError do |exception|
      raise exception
    end
    
    private
    
    def require_admin
      return if current_user.admin?
      raise Pundit::NotAuthorizedError, "Access denied. Admin privileges required."
    end
  end
end
```

**Key Design Decisions:**
- Simple role check via `require_admin` - only admins can access admin routes
- Skips standard Pundit verification (handled by base controller check)
- Uses custom admin layout separate from public application
- Direct exception raising for unauthorized access

### Admin Routes (config/routes.rb)

```ruby
namespace :admin do
  get :metrics
  resources :users, :tours, :bookings, :reviews, :guide_profiles, :weather_snapshots, :email_logs
  
  resources :tours, only: [] do
    resources :tour_add_ons, path: "add-ons" do
      collection do
        post :reorder
      end
    end
  end
end
```

**Admin Sections:**
1. **Dashboard/Metrics** - system statistics
2. **Users Management** - create, read, update, delete users
3. **Tours Management** - view and edit all tours in the system
4. **Bookings Management** - manage all bookings with status updates
5. **Reviews Management** - view and delete reviews
6. **Guide Profiles** - view and edit guide profiles
7. **Weather Snapshots** - view weather data for tours
8. **Email Logs** - view email history
9. **Tour Add-ons** - nested resource for managing add-ons per tour

---

## 3. Pundit Policies

All policies extend `ApplicationPolicy` with role-based authorization. The default policy allows all actions for authenticated users.

### ApplicationPolicy Base (app/policies/application_policy.rb)

```ruby
class ApplicationPolicy
  attr_reader :user, :record
  
  def initialize(user, record)
    @user = user
    @record = record
  end
  
  # Default: true for all actions
  def index?; true; end
  def show?; true; end
  def create?; true; end
  def update?; true; end
  def destroy?; true; end
  # ...
end
```

### Resource-Specific Policies

#### 1. **UserPolicy** (Restrictive Access)
```ruby
class UserPolicy < ApplicationPolicy
  def index?
    user.admin?  # Only admins can list users
  end
  
  def show?
    user.admin? || record == user  # Admin or self
  end
  
  def update?
    user.admin? || record == user  # Admin or self
  end
  
  def destroy?
    user.admin?  # Only admins
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      user.admin? ? scope.all : scope.where(id: user.id)
    end
  end
end
```
**Logic:** Admins see all users; regular users only see themselves.

#### 2. **TourPolicy** (Guide + Admin)
```ruby
class TourPolicy < ApplicationPolicy
  def show?
    true  # Publicly accessible
  end
  
  def update?
    return false if user.nil?
    user.admin? || (user.guide? && record.guide == user)
  end
  
  def destroy?
    return false if user.nil?
    user.admin? || (user.guide? && record.guide == user)
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.admin? ? scope.all : (user&.guide? ? scope.where(guide: user) : scope.all)
    end
  end
end
```
**Logic:** Shows are public; only guide owner or admin can modify.

#### 3. **BookingPolicy** (Multiple Role Access)
```ruby
class BookingPolicy < ApplicationPolicy
  def create?
    user.present?  # Any logged-in user
  end
  
  def update?
    user.admin? || (user.tourist? && record.user == user)
  end
  
  def destroy?
    user.admin? || (user.tourist? && record.user == user)
  end
  
  def cancel?
    user.admin? || (user.tourist? && record.user == user) || (user.guide? && record.tour.guide == user)
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
**Logic:** Complex scoping - each role sees different bookings.

#### 4. **ReviewPolicy** (Conditional Creation)
```ruby
class ReviewPolicy < ApplicationPolicy
  def create?
    user.admin? || (user.tourist? && record.user == user && record.tour.done?)
  end
  
  def destroy?
    user.admin? || (user.tourist? && record.user == user)
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.admin? ? scope.all : scope.where(user: user)
    end
  end
end
```
**Logic:** Tourists can only review completed tours they participated in.

#### 5. **GuideProfilePolicy** (Guide + Admin)
```ruby
class GuideProfilePolicy < ApplicationPolicy
  def update?
    user.admin? || (user.guide? && record.user == user)
  end
  
  def destroy?
    user.admin? || (user.guide? && record.user == user)
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      user.admin? ? scope.all : scope.where(user: user)
    end
  end
end
```
**Logic:** Guides manage their own profiles; admins manage all.

#### 6. **TourAddOnPolicy** (Multi-Scope)
```ruby
class TourAddOnPolicy < ApplicationPolicy
  def index?
    user.admin? || (user.guide? && record.tour.guide == user)
  end
  
  def show?
    record.active?  # Only active add-ons are public
  end
  
  def create?
    user.admin? || (user.guide? && record.tour.guide == user)
  end
  
  def reorder?
    update?  # Same as update
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin?
        scope.all
      elsif user&.guide?
        scope.joins(:tour).where(tours: { guide: user })
      else
        scope.active
      end
    end
  end
end
```
**Logic:** Tiered access - admin sees all, guides see their add-ons, tourists see active only.

#### 7. **Other Policies**
- `EmailLogPolicy` - Likely admin-only or read-only
- `CommentPolicy` - Users manage their comments
- `HistoryPolicy` - User-specific access
- `BookingAddOnPolicy` - Nested resource authorization

---

## 4. Admin Controllers

All admin controllers follow the same pattern: inherit from `Admin::BaseController`, require admin access, and use Turbo Streams for dynamic updates.

### Admin::UsersController
**Path:** `/admin/users`

**Actions:**
- `index` - List users with search by name/email
- `show` - View user details
- `new` / `create` - Add new user
- `edit` / `update` - Modify user role, email, name, phone, password
- `destroy` - Delete user

**Special Features:**
- Turbo Stream broadcasts on user creation/update
- Modal-based creation
- Pagination (25 per page)
- Inline updates with notifications

**Parameters Accepted:**
```ruby
params.expect(user: %i[name email role phone password password_confirmation])
```

### Admin::ToursController
**Path:** `/admin/tours`

**Actions:**
- `index` - List all tours with status/title filtering
- `show` - View tour details
- `new` / `create` - Create new tour
- `edit` / `update` - Edit tour (context-aware for inline editing)
- `destroy` - Delete tour

**Special Features:**
- Context-aware inline editing (different partials for different pages)
- Status filtering (scheduled, in_progress, completed)
- Pagination (25 per page)
- Turbo Stream updates with notifications

**Parameters Accepted:**
```ruby
params.expect(tour: [:title, :description, :guide_id, :status, :capacity,
                     :price_cents, :currency, :location_name, :latitude, :longitude,
                     :starts_at, :ends_at, :tour_type, :booking_deadline_hours, :cover_image,
                     { images: [] }])
```

### Admin::BookingsController
**Path:** `/admin/bookings`

**Actions:**
- `index` - List all bookings with status filtering
- `edit` / `update` - Update booking status and notes
- `destroy` - Delete booking

**Special Features:**
- Inline editing for status/notes
- Status filtering (pending, confirmed, completed, cancelled)
- Includes booking add-ons in eager loading
- Pagination (25 per page)

**Parameters Accepted:**
```ruby
params.expect(booking: %i[status notes])
```

### Admin::ReviewsController
**Path:** `/admin/reviews`

**Actions:**
- `index` - List all reviews
- `show` - View review details
- `destroy` - Delete inappropriate reviews

**Special Features:**
- Includes user and guide profile associations
- Read-only except for deletion
- Pagination (25 per page)

### Admin::GuideProfilesController
**Path:** `/admin/guide_profiles`

**Actions:**
- `index` - List all guide profiles
- `show` - View guide with associated tours and comments
- `edit` / `update` - Inline edit guide profile

**Special Features:**
- Shows guide's tours with status
- Shows comments on guide profile
- Inline editing via Turbo Streams
- Context-aware tour management

**Parameters Accepted:**
```ruby
params.expect(guide_profile: %i[bio certifications languages years_of_experience])
```

### Admin::TourAddOnsController
**Path:** `/admin/tours/:tour_id/add-ons`

**Actions:**
- `index` - List add-ons for a tour
- `new` / `create` - Create add-on
- `edit` / `update` - Inline edit add-on
- `destroy` - Delete add-on
- `reorder` - Reorder add-ons via drag-and-drop

**Special Features:**
- Uses explicit Pundit authorization checks
- Turbo Stream form updates
- Reorder via POST with position hash
- Dynamic position management

**Parameters Accepted:**
```ruby
params.expect(tour_add_on: %i[name description addon_type price_cents currency
                              pricing_type maximum_quantity active position])
```

### Admin::WeatherSnapshotsController
**Path:** `/admin/weather_snapshots`

**Actions:** Likely read-only index/show

### Admin::EmailLogsController
**Path:** `/admin/email_logs`

**Actions:** Likely read-only index/show

### AdminController (Dashboard)
**Path:** `/admin/metrics`

**Features:**
- Guide count
- Tourist count
- Total tours
- Upcoming scheduled tours
- Booking statistics (7-day, 30-day)
- Recent bookings list (last 10)

```ruby
def metrics
  @guide_count = User.where(role: :guide).count
  @tourist_count = User.where(role: :tourist).count
  @tour_count = Tour.count
  @upcoming_tour_count = Tour.where(status: :scheduled).where("starts_at > ?", Time.current).count
  @booking_count_7_days = Booking.where("created_at > ?", 7.days.ago).count
  @booking_count_30_days = Booking.where("created_at > ?", 30.days.ago).count
  @recent_bookings = Booking.includes(:tour, :user).order(created_at: :desc).limit(10)
end
```

---

## 5. Inline Editing Functionality

The application implements comprehensive inline editing via the **InlineEditable concern** (app/controllers/concerns/inline_editable.rb).

### Core Methods

#### 1. **render_inline_edit_form**
Renders an edit form for inline editing via Turbo Stream.

```ruby
def render_inline_edit_form(resource, partial:, locals: {})
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        dom_id(resource),
        partial: partial,
        locals: { resource.model_name.param_key.to_sym => resource }.merge(locals)
      )
    end
    format.html
  end
end
```

#### 2. **render_inline_update_success**
Replaces edited element with display view and shows success notification.

```ruby
def render_inline_update_success(resource, display_partial:, message:, additional_streams: [], locals: {})
  respond_to do |format|
    format.turbo_stream do
      streams = [
        turbo_stream.replace(dom_id(resource), partial: display_partial, ...),
        turbo_stream.append("notifications", partial: notification_partial_path, ...)
      ] + additional_streams
      render turbo_stream: streams
    end
    format.html { redirect_to resource, notice: message }
  end
end
```

#### 3. **render_inline_update_failure**
Re-renders edit form with validation errors.

```ruby
def render_inline_update_failure(resource, partial:, locals: {})
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        dom_id(resource),
        partial: partial,
        ...
      ), status: :unprocessable_entity
    end
    format.html { render :edit, status: :unprocessable_entity }
  end
end
```

#### 4. **render_inline_delete_success**
Removes element and shows notification.

```ruby
def render_inline_delete_success(resource, message:, redirect_path:)
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.remove(dom_id(resource)),
        turbo_stream.append("notifications", partial: notification_partial_path, ...)
      ]
    end
    format.html { redirect_to redirect_path, notice: message }
  end
end
```

#### 5. **render_context_aware_inline_form**
Selects different edit form partial based on request referer (e.g., edit from tours index vs guide profiles).

```ruby
def render_context_aware_inline_form(resource, context_mapping:, default_partial:, action:)
  # Maps referer keywords to partial paths
  # Example:
  # context_mapping: {
  #   "guide_profiles" => "admin/guide_profiles/tour",
  #   "dashboard" => "guides/dashboard/tour"
  # }
end
```

### Current Inline Editing Usage

**Tours in Admin Interface:**
```ruby
# app/controllers/admin/tours_controller.rb

def edit
  respond_to do |format|
    format.turbo_stream do
      if request.referer&.include?("guide_profiles")
        render turbo_stream: turbo_stream.replace(
          dom_id(@tour),
          partial: "admin/guide_profiles/tour_edit_form",
          locals: { tour: @tour }
        )
      else
        render turbo_stream: turbo_stream.replace(
          dom_id(@tour),
          partial: "admin/tours/tour_edit_form",
          locals: { tour: @tour }
        )
      end
    end
  end
end

def update
  if @tour.update(tour_params)
    respond_to do |format|
      format.turbo_stream do
        # Different rendering based on context (guide_profiles vs tours)
      end
    end
  end
end
```

**Bookings Inline Editing:**
```ruby
# app/controllers/admin/bookings_controller.rb

def edit
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        dom_id(@booking),
        partial: "admin/bookings/booking_edit_form",
        locals: { booking: @booking }
      )
    end
  end
end
```

**Guide Profiles Inline Editing:**
```ruby
# app/controllers/admin/guide_profiles_controller.rb

def update
  if @guide_profile.update(guide_profile_params)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(
            dom_id(@guide_profile, :profile),
            partial: "admin/guide_profiles/profile_section",
            locals: { guide_profile: @guide_profile }
          ),
          turbo_stream.append("notifications", ...)
        ]
      end
    end
  end
end
```

**Tour Add-ons with Explicit Authorization:**
```ruby
# app/controllers/admin/tour_add_ons_controller.rb

def edit
  authorize @tour_add_on  # Explicit Pundit check
  
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        dom_id(@tour_add_on),
        partial: "admin/tour_add_ons/edit_form",
        locals: { tour: @tour, tour_add_on: @tour_add_on }
      )
    end
  end
end
```

### Notification Partial Path Detection

The concern includes a helper method that determines which notification partial to use:

```ruby
private

def notification_partial_path
  if controller_path.start_with?("admin/")
    "admin/shared/notification"
  else
    "shared/notification"
  end
end
```

---

## 6. Admin Interface Structure

### Admin Layout (app/views/layouts/admin.html.erb)

**Layout Architecture:**
```html
<div class="flex h-screen overflow-hidden">
  <!-- Persistent Sidebar -->
  <%= render "admin/shared/sidebar" %>
  
  <!-- Main Content Area -->
  <main class="flex-1 flex flex-col overflow-hidden">
    <!-- Header -->
    <%= render "admin/shared/header" %>
    
    <!-- Flash Messages -->
    <%= render "application/flash" %>
    
    <!-- Turbo Frame for page transitions -->
    <%= turbo_frame_tag "admin_content", data: { turbo_action: "advance" } %>
  </main>
</div>

<!-- Modal Container -->
<%= turbo_frame_tag "modal" %>

<!-- Toast Notifications -->
<div id="notifications" data-controller="notification"></div>

<!-- Real-time Updates -->
<%= turbo_stream_from "admin_notifications_#{current_user.id}" %>
```

### Sidebar Navigation (app/views/admin/shared/_sidebar.html.erb)

**Navigation Structure:**
1. **Dashboard** - `admin_metrics_path`
2. **Users** - `admin_users_path`
3. **Tours** - `admin_tours_path`
4. **Bookings** - `admin_bookings_path`
5. **Reviews** - `admin_reviews_path`
6. **Guide Profiles** - `admin_guide_profiles_path`
7. **Weather** - `admin_weather_snapshots_path`
8. **Email Logs** - `admin_email_logs_path`

**Features:**
- Desktop sidebar (hidden on mobile)
- Mobile bottom navigation bar
- Active page highlighting
- Back to site link
- Dark theme (bg-gray-900)

### Header (app/views/admin/shared/_header.html.erb)

**Features:**
- Page title
- Current user name
- Sign out button
- Light card styling

### Row/Card Components

**Tours Row (_tour.html.erb):**
```erb
<tr>
  <td>Title / Location</td>
  <td>Guide Name</td>
  <td>Status Badge</td>
  <td>Start Date</td>
  <td>Price</td>
  <td>Actions: View | Add-ons | Edit | Delete</td>
</tr>
```

**Bookings Row (_booking.html.erb):**
```erb
<tr>
  <td>Tour Title / Location</td>
  <td>Tourist Name / Email</td>
  <td>Status Badge</td>
  <td>Created Date</td>
  <td>Actions: Edit | Delete</td>
</tr>
```

### Form Components

**Tour Edit Form (_tour_edit_form.html.erb):**
- Title, description
- Guide selection
- Status dropdown
- Capacity, pricing
- Location info
- Dates/times
- Tour type
- Booking deadline
- Images

**Booking Edit Form (_booking_edit_form.html.erb):**
- Status dropdown
- Notes textarea

### Notifications

**Notification Partial (admin/shared/_notification.html.erb):**
- Toast-style notifications
- Success/error/info/warning types
- Auto-dismiss capability
- Top-right corner positioning

---

## 7. Authorization Flow

### Request Flow Diagram

```
Admin Request
    ↓
Routes check: /admin/* path
    ↓
Admin::BaseController
    ↓
before_action: authenticate_user!
    ↓
before_action: require_admin
    ↓
User has admin? role?
    ├─ NO → raise Pundit::NotAuthorizedError
    └─ YES → continue to controller action
    ↓
Controller Action
    ├─ May include explicit Pundit checks (e.g., TourAddOnsController)
    ↓
Response (HTML or Turbo Stream)
```

### Authorization Decision Points

1. **Route Level** - No special check; Rails routing handles `/admin` namespace
2. **Controller Level** - `Admin::BaseController.require_admin` checks role
3. **Action Level** - Some actions use explicit `authorize` calls (e.g., TourAddOnsController)
4. **Policy Level** - Policies define scopes for index actions
5. **View Level** - Conditional rendering based on user permissions (not implemented in this admin)

---

## 8. Security Considerations

### Implemented Security Measures

1. **Authentication Required**
   - `before_action :authenticate_user!` on all admin controllers
   - Devise integration for user sessions

2. **Role-Based Access Control**
   - Simple admin role check
   - No granular permission system (single admin role has all access)

3. **Information Disclosure Prevention**
   - Unauthorized access returns 404 (RecordNotFound)
   - Doesn't reveal whether resource exists or user lacks access

4. **CSRF Protection**
   - Turbo handles token inclusion automatically
   - Rails default CSRF protection active

5. **Parameter Validation**
   - Strong parameters on all actions
   - Explicit parameter expectations

6. **Scoped Queries**
   - Admin sees all data (by design)
   - Tour add-ons scoped to tour

### Potential Improvements

1. **Granular Admin Permissions** - Could implement sub-admin roles (e.g., ContentMod, ReviewMod)
2. **Audit Logging** - Track all admin actions
3. **Admin Activity Log** - See who did what and when
4. **Soft Deletes** - Archive instead of delete
5. **Version History** - Track changes to records
6. **Two-Factor Authentication** - Extra security for admin accounts
7. **Admin Onboarding Approval** - Require owner to grant admin access
8. **Rate Limiting** - Prevent admin action spam
9. **IP Whitelisting** - Restrict admin access to known IPs

---

## 9. Real-Time Features

### Turbo Stream Broadcasts

The application implements real-time updates for admin dashboards:

**User Model Broadcasts:**
```ruby
after_create_commit :broadcast_created_to_admin
after_update_commit :broadcast_updated_to_admin

private

def broadcast_created_to_admin
  User.where(role: :admin).find_each do |admin|
    broadcast_prepend_to(
      "admin_users_#{admin.id}",
      target: "users_table_body",
      partial: "admin/users/user",
      locals: { user: self }
    )
  end
end

def broadcast_updated_to_admin
  User.where(role: :admin).find_each do |admin|
    broadcast_replace_to(
      "admin_users_#{admin.id}",
      target: dom_id(self),
      partial: "admin/users/user",
      locals: { user: self }
    )
  end
end
```

**Admin Layout Subscription:**
```erb
<% if current_user %>
  <%= turbo_stream_from "admin_notifications_#{current_user.id}" %>
<% end %>
```

### Turbo Frame for Page Transitions

All navigation uses Turbo frames for fast page transitions:
```erb
<%= turbo_frame_tag "admin_content", data: { turbo_action: "advance" } do %>
  <%= yield %>
<% end %>
```

---

## 10. Technology Stack

### Backend
- **Rails 8** - Web framework
- **Devise** - Authentication
- **Pundit** - Authorization
- **Turbo Rails** - Real-time updates and navigation
- **Active Storage** - File uploads
- **Kaminari** - Pagination

### Frontend
- **Tailwind CSS** - Styling
- **Stimulus.js** - JavaScript behavior
- **Turbo Streams** - Real-time updates
- **HTML ERB Templates** - View layer

### Database
- **PostgreSQL** - Primary data store
- **Active Record** - ORM

---

## 11. Key Files Reference

### Controllers
- `/app/controllers/admin/base_controller.rb` - Base admin controller with require_admin check
- `/app/controllers/admin/users_controller.rb` - User management
- `/app/controllers/admin/tours_controller.rb` - Tour management
- `/app/controllers/admin/bookings_controller.rb` - Booking management
- `/app/controllers/admin/reviews_controller.rb` - Review management
- `/app/controllers/admin/guide_profiles_controller.rb` - Guide profile management
- `/app/controllers/admin/tour_add_ons_controller.rb` - Tour add-ons management
- `/app/controllers/admin_controller.rb` - Dashboard/metrics

### Concerns
- `/app/controllers/concerns/inline_editable.rb` - Inline editing functionality

### Policies
- `/app/policies/application_policy.rb` - Base policy
- `/app/policies/user_policy.rb` - User authorization
- `/app/policies/tour_policy.rb` - Tour authorization
- `/app/policies/booking_policy.rb` - Booking authorization
- `/app/policies/review_policy.rb` - Review authorization
- `/app/policies/guide_profile_policy.rb` - Guide profile authorization
- `/app/policies/tour_add_on_policy.rb` - Tour add-on authorization
- Other specific policies for remaining resources

### Views
- `/app/views/layouts/admin.html.erb` - Admin layout
- `/app/views/admin/shared/` - Shared components (header, sidebar, notification)
- `/app/views/admin/[resource]/` - Resource-specific views
  - Users, Tours, Bookings, Reviews, Guide Profiles, Weather Snapshots, Email Logs

### Models
- `/app/models/user.rb` - User model with role enum and broadcasts

---

## 12. Summary

The admin interface is a well-structured, role-based system with:

1. **Simple but secure** - Single admin role with basic require_admin check
2. **Policy-driven** - Pundit policies define authorization rules
3. **Real-time capable** - Turbo Streams enable live updates
4. **Inline editing** - Context-aware form rendering for quick edits
5. **User-friendly** - Dashboard with sidebar navigation and notifications
6. **Extensible** - Inline editing concern can be reused throughout the app
7. **Responsive** - Desktop sidebar + mobile bottom navigation

The system successfully manages multiple resource types with appropriate access controls, and provides a smooth admin experience through modern Rails technologies.
