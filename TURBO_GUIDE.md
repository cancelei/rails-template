# Turbo-First Implementation Guide

## Table of Contents

1. [Introduction](#introduction)
2. [The Turbo-First Philosophy](#the-turbo-first-philosophy)
3. [Turbo Drive](#turbo-drive)
4. [Turbo Frames](#turbo-frames)
5. [Turbo Streams](#turbo-streams)
6. [When to Use Stimulus](#when-to-use-stimulus)
7. [Implementation Examples from Our Codebase](#implementation-examples-from-our-codebase)
8. [Best Practices](#best-practices)
9. [Common Patterns](#common-patterns)
10. [Troubleshooting](#troubleshooting)

---

## Introduction

This guide documents the Turbo-first approach to building interactive features
in our Rails application. Hotwire's Turbo provides three powerful tools that
work together to create fast, modern web applications without writing much
JavaScript:

- **Turbo Drive**: Accelerates links and form submissions
- **Turbo Frames**: Decomposes pages into independent contexts
- **Turbo Streams**: Delivers page updates over WebSockets, SSE, or in response
  to form submissions

**Key Principle**: Always prefer Turbo over custom JavaScript. Only reach for
Stimulus when you need client-side interactivity that Turbo can't handle.

---

## The Turbo-First Philosophy

### Decision Tree for Feature Implementation

```
Need to build a feature?
├─ Does it require client-side state or DOM manipulation?
│  ├─ YES → Consider Stimulus (e.g., toggling visibility, animations)
│  └─ NO → Continue
│
├─ Does it need to update part of a page?
│  ├─ After a form submission? → Use Turbo Streams
│  ├─ Real-time updates? → Use Turbo Streams with turbo_stream_from
│  └─ Navigation within a section? → Use Turbo Frames
│
└─ Is it just navigation? → Turbo Drive handles it automatically!
```

### Why Turbo-First?

1. **Less JavaScript**: Turbo handles most interactions with HTML over the wire
2. **Better Performance**: Browser-native rendering is faster than JavaScript
   frameworks
3. **Simpler Maintenance**: Server-side logic is easier to test and maintain
4. **Progressive Enhancement**: Features work without JavaScript when possible
5. **SEO Friendly**: Server-rendered HTML is easily crawled

---

## Turbo Drive

Turbo Drive is automatically enabled when you include `turbo-rails` in your
application. It intercepts link clicks and form submissions, making page
navigation feel instant.

### What Turbo Drive Does

- Intercepts all `<a>` clicks and form submissions
- Uses `fetch()` to request HTML from the server
- Replaces the `<body>` content while preserving the `<head>`
- Updates the browser's history and URL
- Shows a progress bar for slow requests

### Configuration

Turbo Drive is enabled by default. You don't need to configure anything!

### Disabling Turbo Drive (When Needed)

Sometimes you need to disable Turbo Drive for specific links or forms:

```erb
<%# Disable for a single link %>
<%= link_to "Download PDF", document_path, data: { turbo: false } %>

<%# Disable for a form %>
<%= form_with model: @user, data: { turbo: false } do |f| %>
  <%# This will be a full page reload %>
<% end %>

<%# Disable for an entire section %>
<div data-turbo="false">
  <%# All links and forms inside here will use traditional navigation %>
</div>
```

### Pre-loading Pages

Speed up navigation by preloading pages on hover:

```erb
<%= link_to "Next Page", next_page_path, data: { turbo_preload: true } %>
```

### Turbo Drive Events

Listen to Turbo Drive lifecycle events in JavaScript when needed:

```javascript
// Before a visit starts
document.addEventListener('turbo:before-visit', event => {
  // event.detail.url is the destination
  // You can cancel: event.preventDefault()
});

// After the page renders
document.addEventListener('turbo:load', () => {
  // Equivalent to DOMContentLoaded but fires after Turbo navigations
});

// Before caching the current page
document.addEventListener('turbo:before-cache', () => {
  // Clean up: close modals, reset forms, etc.
});
```

---

## Turbo Frames

Turbo Frames decompose your page into independent contexts that can be
lazy-loaded and navigate without affecting the rest of the page.

### Basic Frame Structure

```erb
<turbo-frame id="messages">
  <h2>Messages</h2>

  <%= link_to "New Message", new_message_path %>

  <div id="message-list">
    <%= render @messages %>
  </div>
</turbo-frame>
```

When you click the "New Message" link:

1. Turbo intercepts the click
2. Fetches the HTML from `/messages/new`
3. Extracts the matching `<turbo-frame id="messages">` from the response
4. Replaces the frame content (only that section updates!)

### Frame Navigation Rules

**By default**, links and forms inside a frame navigate the frame:

```erb
<turbo-frame id="modal">
  <%# This link will load the response into THIS frame %>
  <%= link_to "Edit User", edit_user_path(@user) %>

  <%# This form submission will update THIS frame %>
  <%= form_with model: @user do |f| %>
    <%# ... %>
  <% end %>
</turbo-frame>
```

### Breaking Out of Frames

Use `data-turbo-frame="_top"` to navigate the whole page:

```erb
<turbo-frame id="message">
  <%# This navigates the whole page, not just the frame %>
  <%= link_to "Back to List", messages_path, data: { turbo_frame: "_top" } %>

  <%# Or use the target attribute on the frame itself %>
</turbo-frame>

<%# All links in this frame navigate the whole page %>
<turbo-frame id="message" target="_top">
  <%= link_to "Home", root_path %> <%# Navigates entire page %>
</turbo-frame>
```

### Targeting Different Frames

Navigate a different frame from outside or inside another frame:

```erb
<%# Button outside any frame that opens a modal frame %>
<%= link_to "Edit User",
            edit_admin_user_path(@user),
            data: { turbo_frame: "modal" } %>

<%# The modal frame elsewhere on the page %>
<turbo-frame id="modal"></turbo-frame>
```

**Example from our codebase** (`app/views/admin/bookings/_booking.html.erb:31`):

```erb
<%= link_to "Edit",
            edit_admin_booking_path(booking),
            class: "text-indigo-600 hover:text-indigo-900 mr-4",
            data: { turbo_frame: "modal" } %>
```

### Lazy Loading Frames

Load content only when needed using the `src` attribute:

```erb
<%# Frame loads immediately when page renders %>
<turbo-frame id="analytics" src="/admin/analytics">
  <p>Loading analytics...</p>
</turbo-frame>

<%# Frame loads only when it becomes visible (lazy) %>
<turbo-frame id="comments" src="/posts/1/comments" loading="lazy">
  <p>Loading comments...</p>
</turbo-frame>
```

### Frame with History Management

Make frame navigations update the URL and browser history:

```erb
<turbo-frame id="admin_content" data-turbo-action="advance">
  <%# Clicking links inside will update the URL %>
  <%= yield %>
</turbo-frame>
```

**Example from our codebase** (`app/views/layouts/admin.html.erb:41`):

```erb
<%= turbo_frame_tag "admin_content", data: { turbo_action: "advance" } do %>
  <%= yield %>
<% end %>
```

This allows users to:

- Use the back/forward buttons
- Bookmark specific states
- Share URLs to specific admin pages

### Common Frame Patterns

#### 1. Modal Pattern

```erb
<%# In your layout %>
<turbo-frame id="modal" class="modal-container" data-controller="modal">
</turbo-frame>

<%# Trigger from anywhere %>
<%= link_to "Edit", edit_path(@record), data: { turbo_frame: "modal" } %>

<%# In the edit view %>
<turbo-frame id="modal">
  <div class="modal-content">
    <%= form_with model: @record do |f| %>
      <%# ... %>
      <%= link_to "Cancel", "#", data: { action: "modal#close" } %>
    <% end %>
  </div>
</turbo-frame>
```

#### 2. Inline Editing Pattern

```erb
<%# Show view %>
<turbo-frame id="<%= dom_id(@post) %>">
  <h1><%= @post.title %></h1>
  <p><%= @post.body %></p>
  <%= link_to "Edit", edit_post_path(@post) %>
</turbo-frame>

<%# Edit view %>
<turbo-frame id="<%= dom_id(@post) %>">
  <%= form_with model: @post do |f| %>
    <%= f.text_field :title %>
    <%= f.text_area :body %>
    <%= f.submit %>
    <%= link_to "Cancel", @post %>
  <% end %>
</turbo-frame>
```

#### 3. Pagination Pattern

```erb
<turbo-frame id="posts">
  <div id="posts-list">
    <%= render @posts %>
  </div>

  <%# Pagination links will update only this frame %>
  <%= paginate @posts %>
</turbo-frame>
```

---

## Turbo Streams

Turbo Streams allow you to make surgical updates to the page, adding, removing,
or updating specific elements without replacing entire frames.

### The Seven Stream Actions

Turbo Streams provide seven actions to manipulate the DOM:

```erb
<%# 1. APPEND - Add content to the end of a container %>
<%= turbo_stream.append "messages", @message %>

<%# 2. PREPEND - Add content to the beginning %>
<%= turbo_stream.prepend "messages", @message %>

<%# 3. REPLACE - Replace an element entirely %>
<%= turbo_stream.replace @message %>
<%= turbo_stream.replace "message_1", partial: "messages/message" %>

<%# 4. UPDATE - Replace the contents (innerHTML) of an element %>
<%= turbo_stream.update "unread_count", "5" %>

<%# 5. REMOVE - Remove an element from the page %>
<%= turbo_stream.remove @message %>

<%# 6. BEFORE - Insert content before an element %>
<%= turbo_stream.before "message_1", partial: "messages/new" %>

<%# 7. AFTER - Insert content after an element %>
<%= turbo_stream.after "message_1", partial: "messages/new" %>

<%# 8. REFRESH - Reload the page (or debounced with request-id) %>
<%= turbo_stream.refresh %>
```

### Stream Response Format

Create a `.turbo_stream.erb` view to respond to Turbo Stream requests:

```erb
<%# app/views/comments/create.turbo_stream.erb %>

<%# Add the new comment to the list %>
<%= turbo_stream.prepend "comments", @comment %>

<%# Clear the form %>
<%= turbo_stream.replace "comment_form",
    partial: "comments/form",
    locals: { comment: Comment.new } %>

<%# Update the count %>
<%= turbo_stream.update "comment_count", "#{@post.comments.count} comments" %>
```

### Controller Response

```ruby
# app/controllers/comments_controller.rb
def create
  @comment = @post.comments.build(comment_params)

  if @comment.save
    respond_to do |format|
      format.turbo_stream  # Renders create.turbo_stream.erb
      format.html { redirect_to @post }
    end
  else
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "comment_form",
          partial: "comments/form",
          locals: { comment: @comment }
        )
      }
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

**Example from our codebase** (`app/controllers/comments_controller.rb:23-36`):

```ruby
if @comment.save
  respond_to do |format|
    format.html { redirect_to @guide_profile, notice: "Comment added successfully." }
    format.turbo_stream
  end
else
  respond_to do |format|
    format.html { redirect_to @guide_profile, alert: "Failed to add comment." }
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace("comment_form", partial: "comments/form",
                                                                locals: { guide_profile: @guide_profile, comment: @comment })
    end
  end
end
```

### Targeting Multiple Elements

Use CSS selectors to target multiple elements at once:

```erb
<%# Update all elements with class 'like-count' %>
<%= turbo_stream.update_all ".like-count", "42" %>

<%# Remove all elements matching a selector %>
<turbo-stream action="remove" targets=".flash-message"></turbo-stream>
```

### Broadcasting with Turbo Streams

For real-time updates, broadcast Turbo Streams over Action Cable:

#### 1. Enable broadcasts in your model:

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  belongs_to :room

  # Broadcast after creation
  after_create_commit -> {
    broadcast_prepend_to room,
                        target: "messages",
                        partial: "messages/message",
                        locals: { message: self }
  }

  # Broadcast after update
  after_update_commit -> {
    broadcast_replace_to room
  }

  # Broadcast after deletion
  after_destroy_commit -> {
    broadcast_remove_to room
  }
end
```

#### 2. Subscribe in your view:

```erb
<%# app/views/rooms/show.html.erb %>

<%# Subscribe to broadcasts for this room %>
<%= turbo_stream_from @room %>

<div id="messages">
  <%= render @messages %>
</div>
```

**Example from our codebase** (`app/views/layouts/admin.html.erb:56`):

```erb
<% if current_user %>
  <%= turbo_stream_from "admin_notifications_#{current_user.id}" %>
<% end %>
```

#### 3. Broadcast from anywhere:

```ruby
# In a job, service, or controller
@room.broadcast_append_to @room,
                          target: "messages",
                          partial: "messages/message",
                          locals: { message: @message }
```

### Stream from Multiple Channels

You can subscribe to multiple streams on the same page:

```erb
<%# Get updates for the current user %>
<%= turbo_stream_from current_user %>

<%# Get updates for the room %>
<%= turbo_stream_from @room %>

<%# Get updates for a custom channel %>
<%= turbo_stream_from "global_notifications" %>
```

---

## When to Use Stimulus

Stimulus should be your **last resort**, used only when Turbo cannot handle the
interaction.

### ✅ Valid Use Cases for Stimulus

1. **Client-side UI State** - Things that don't require server interaction
   - Toggling visibility of elements
   - Showing/hiding modals or dropdowns
   - Form field visibility based on other fields
   - Tab switching within a page

2. **DOM Manipulation** - Client-side only changes
   - Auto-expanding textareas
   - Character counters
   - Copy-to-clipboard functionality
   - Drag and drop reordering (before persisting)

3. **Enhancing Turbo** - Adding polish to Turbo interactions
   - Loading indicators beyond the default progress bar
   - Animations/transitions for Turbo updates
   - Focus management after Turbo navigation
   - Custom form validation UI

4. **Third-party Integration** - Wrapping external JavaScript libraries
   - Stripe payment forms
   - Google Maps
   - Rich text editors
   - Date pickers

5. **Real-time User Input** - Things happening as the user types/interacts
   - Auto-saving drafts (debounced)
   - Live search (debounced, then use Turbo for results)
   - Character/word counting
   - Form validation feedback

### ❌ When NOT to Use Stimulus

1. **Form Submissions** - Use Turbo Streams instead

   ```erb
   <%# ❌ Don't do this with Stimulus %>
   <button data-action="click->form#submit">Submit</button>

   <%# ✅ Do this with Turbo %>
   <%= form_with model: @post do |f| %>
     <%= f.submit %>
   <% end %>
   ```

2. **Page Updates After Actions** - Use Turbo Streams instead

   ```ruby
   # ❌ Don't render JSON and handle it with Stimulus
   render json: { status: 'success', count: @post.likes.count }

   # ✅ Use Turbo Streams
   render turbo_stream: turbo_stream.update("like_count", @post.likes.count)
   ```

3. **Navigation** - Turbo Drive and Frames handle this

   ```erb
   <%# ❌ Don't do this %>
   <button data-action="click->navigation#goto" data-url="/posts">

   <%# ✅ Just use a link %>
   <%= link_to "Posts", posts_path %>
   ```

### Stimulus Controller Examples

#### Example 1: Modal Controller (Valid Use Case)

**Purpose**: Manage modal visibility and cleanup

```javascript
// app/frontend/stimulus/controllers/modal_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this.element.showModal?.();
    this.element.classList.remove('hidden');
    document.body.style.overflow = 'hidden';

    this.element.addEventListener('click', this.backdropClick.bind(this));
  }

  disconnect() {
    this.element.classList.add('hidden');
    document.body.style.overflow = '';
  }

  close(event) {
    event?.preventDefault();
    this.element.innerHTML = '';
    this.disconnect();
  }

  backdropClick(event) {
    if (event.target === this.element) {
      this.close();
    }
  }
}
```

**Usage**:

```erb
<turbo-frame id="modal" data-controller="modal">
  <%# Modal content loaded here %>
  <button data-action="click->modal#close">Close</button>
</turbo-frame>
```

#### Example 2: Search Controller (Valid Use Case)

**Purpose**: Auto-submit search form after debounce

```javascript
// app/frontend/stimulus/controllers/search_controller.js
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['input'];
  static values = { delay: { type: Number, default: 300 } };

  connect() {
    this.timeout = null;
  }

  submit() {
    clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, this.delayValue);
  }
}
```

**Usage**:

```erb
<%= form_with url: search_path,
              method: :get,
              data: {
                controller: "search",
                turbo_frame: "results"
              } do |f| %>
  <%= f.text_field :q,
                   data: {
                     action: "input->search#submit",
                     search_target: "input"
                   } %>
<% end %>

<turbo-frame id="results">
  <%# Search results loaded here via Turbo %>
</turbo-frame>
```

#### Example 3: ~~Like Controller~~ (Actually, DON'T do this!)

Our codebase has a `like_controller.js` that uses `fetch()` to submit likes.
**This is unnecessary!** Here's why:

**❌ Current Implementation**
(`app/frontend/stimulus/controllers/like_controller.js`):

```javascript
async toggle(event) {
  event.preventDefault()
  const form = event.target.closest('form')
  const url = form.action

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Accept': 'text/vnd.turbo-stream.html' },
    body: new FormData(form)
  })

  const html = await response.text()
  Turbo.renderStreamMessage(html)
}
```

**✅ Better: Pure Turbo Solution**

Just let Turbo handle the form submission! No Stimulus needed:

```erb
<%# app/views/comments/_like_button.html.erb %>
<%= button_to toggle_like_comment_path(comment),
              method: :post,
              class: "like-button",
              params: { format: :turbo_stream } do %>
  <span><%= is_liked ? '❤️' : '🤍' %></span>
  <span><%= comment.likes_count %></span>
<% end %>
```

The controller already responds with Turbo Streams:

```ruby
# app/controllers/comments_controller.rb
def toggle_like
  # ... toggle logic ...

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        "like_button_#{@comment.id}",
        partial: "comments/like_button",
        locals: { comment: @comment, is_liked: @is_liked }
      )
    end
  end
end
```

**The Stimulus controller is completely unnecessary!** Turbo handles:

- Form submission
- Optimistic UI updates (instant feedback)
- Server response processing
- DOM updates via Turbo Stream

---

## Implementation Examples from Our Codebase

### Example 1: Comment System with Turbo Streams

**View** (`app/views/guide_profiles/show.html.erb`):

```erb
<div id="comments-section">
  <%# Form to create new comment %>
  <%= turbo_frame_tag "comment_form" do %>
    <%= render "comments/form",
               guide_profile: @guide_profile,
               comment: @guide_profile.comments.build %>
  <% end %>

  <%# Container for comments list %>
  <div id="comments">
    <%= render @comments %>
  </div>
</div>
```

**Controller** (`app/controllers/comments_controller.rb:23-36`):

```ruby
def create
  @comment = @guide_profile.comments.build(comment_params)
  @comment.user = current_user

  if @comment.save
    respond_to do |format|
      format.html { redirect_to @guide_profile, notice: "Comment added." }
      format.turbo_stream  # Renders create.turbo_stream.erb
    end
  else
    respond_to do |format|
      format.html { redirect_to @guide_profile, alert: "Failed to add comment." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "comment_form",
          partial: "comments/form",
          locals: { guide_profile: @guide_profile, comment: @comment }
        )
      end
    end
  end
end
```

**Turbo Stream Response** (`app/views/comments/create.turbo_stream.erb:5-6`):

```erb
<%# Add new comment to top of list %>
<%= turbo_stream.prepend "comments",
    partial: "comments/comment",
    locals: { comment: @comment, guide_profile: @guide_profile, is_liked: false } %>

<%# Reset the form %>
<%= turbo_stream.replace "comment_form",
    partial: "comments/form",
    locals: { guide_profile: @guide_profile, comment: @guide_profile.comments.build } %>
```

**Result**:

- User submits comment form
- Comment is added to the database
- New comment appears at top of list (prepend)
- Form is cleared for next comment
- All without JavaScript or page reload!

### Example 2: Admin Layout with Turbo Frames

**Layout** (`app/views/layouts/admin.html.erb:41-49`):

```erb
<%# Main content area with frame for navigation %>
<div class="flex-1 overflow-y-auto px-6 py-4">
  <%= turbo_frame_tag "admin_content", data: { turbo_action: "advance" } do %>
    <%= yield %>
  <% end %>
</div>

<%# Modal frame for dialogs %>
<%= turbo_frame_tag "modal",
                    class: "hidden fixed inset-0 z-50",
                    data: { controller: "modal" } %>
```

**How it works**:

1. All admin pages are wrapped in the `admin_content` frame
2. Links in sidebar navigate within the frame (partial page updates)
3. URL updates thanks to `data-turbo-action="advance"`
4. Modal frame is targeted by edit/new links: `data: { turbo_frame: "modal" }`

**Example link** (`app/views/admin/bookings/_booking.html.erb:28-31`):

```erb
<%= link_to "Edit",
            edit_admin_booking_path(booking),
            data: { turbo_frame: "modal" } %>
```

When clicked:

- Edit form loads into the modal frame
- Main content stays unchanged
- Modal controller shows the dialog

### Example 3: Like Button with Turbo Streams

**Partial** (`app/views/comments/_like_button.html.erb`):

```erb
<%= button_to toggle_like_comment_path(comment),
              class: "flex items-center gap-1 text-sm #{is_liked ? 'text-blue-600' : 'text-gray-500'} hover:text-blue-600 transition-colors cursor-pointer border-0 bg-transparent p-0",
              style: "outline: none;",
              form_class: "inline-block",
              data: { turbo: true } do %>
  <span class="inline-block transition-transform hover:scale-110">
    <%= is_liked ? '❤️' : '🤍' %>
  </span>
  <span><%= comment.likes_count || 0 %></span>
<% end %>
```

**Turbo Stream View** (`app/views/comments/toggle_like.turbo_stream.erb`):

```erb
<%= turbo_stream.replace "like_button_#{@comment.id}",
    partial: "comments/like_button",
    locals: { comment: @comment, is_liked: @is_liked } %>
```

**Controller** (`app/controllers/comments_controller.rb:57-66`):

```ruby
def toggle_like
  @comment = Comment.find(params[:id])
  like = @comment.likes.find_by(user: current_user)

  if like
    like.destroy
    @is_liked = false
  else
    @comment.likes.create!(user: current_user)
    @is_liked = true
  end

  @comment.reload

  response.headers["Content-Type"] = "text/vnd.turbo-stream.html"
  render turbo_stream: turbo_stream.replace(
    "like_button_#{@comment.id}",
    partial: "comments/like_button",
    locals: { comment: @comment, is_liked: @is_liked }
  )
end
```

**Result**:

- Click button → Turbo submits form
- Server toggles like in database
- Turbo Stream updates just the button
- Count updates, emoji changes
- Zero Stimulus code needed!

### Example 4: Real-time Notifications

**Layout** (`app/views/layouts/admin.html.erb:56`):

```erb
<% if current_user %>
  <%= turbo_stream_from "admin_notifications_#{current_user.id}" %>
<% end %>
```

**Broadcasting** (from anywhere in the app):

```ruby
# In a job, service, or controller
Turbo::StreamsChannel.broadcast_append_to(
  "admin_notifications_#{user.id}",
  target: "notifications",
  partial: "admin/shared/notification",
  locals: { message: "Booking confirmed!", type: "success" }
)
```

**Result**:

- User receives instant notification
- Appears without polling or manual refresh
- Works across tabs and devices
- All with Action Cable + Turbo Streams!

---

## Best Practices

### 1. Always Set IDs on Stream Targets

Turbo Streams need DOM IDs to target elements:

```erb
<%# ✅ Good - has an ID %>
<div id="comments">
  <%= render @comments %>
</div>

<%# ❌ Bad - no ID, Turbo Streams can't target it %>
<div>
  <%= render @comments %>
</div>
```

### 2. Use `dom_id` Helper for Consistent IDs

Rails provides `dom_id` to generate consistent IDs:

```erb
<%# Generates id="post_123" %>
<div id="<%= dom_id(@post) %>">
  <%# ... %>
</div>

<%# Generates id="edit_post_123" %>
<div id="<%= dom_id(@post, :edit) %>">
  <%# ... %>
</div>

<%# In controllers %>
turbo_stream.replace(dom_id(@post), partial: "posts/post")
```

### 3. Match Frame IDs Between Pages

For frames to work, the ID must match between the source and destination:

```erb
<%# app/views/posts/show.html.erb %>
<turbo-frame id="<%= dom_id(@post) %>">
  <%= link_to "Edit", edit_post_path(@post) %>
</turbo-frame>

<%# app/views/posts/edit.html.erb - SAME ID! %>
<turbo-frame id="<%= dom_id(@post) %>">
  <%= form_with model: @post do |f| %>
    <%# ... %>
  <% end %>
</turbo-frame>
```

### 4. Graceful Degradation

Always provide HTML fallbacks:

```ruby
def create
  if @post.save
    respond_to do |format|
      format.turbo_stream  # Fast Turbo update
      format.html { redirect_to @post }  # Fallback for non-Turbo
    end
  else
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace("form", partial: "form")
      }
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

### 5. Keep Frames Small and Focused

Smaller frames perform better and are easier to debug:

```erb
<%# ✅ Good - focused frames %>
<turbo-frame id="post_header">
  <h1><%= @post.title %></h1>
</turbo-frame>

<turbo-frame id="post_body">
  <%= @post.body %>
</turbo-frame>

<turbo-frame id="post_comments">
  <%= render @post.comments %>
</turbo-frame>

<%# ❌ Bad - one giant frame %>
<turbo-frame id="post">
  <%# Everything in here %>
</turbo-frame>
```

### 6. Use Descriptive Frame IDs

Good IDs make debugging easier:

```erb
<%# ✅ Good - clear what it contains %>
<turbo-frame id="user_profile_sidebar">
<turbo-frame id="post_comments_list">
<turbo-frame id="admin_booking_modal">

<%# ❌ Bad - unclear purpose %>
<turbo-frame id="frame1">
<turbo-frame id="content">
<turbo-frame id="stuff">
```

### 7. Clean Up Before Caching

Turbo caches pages for back/forward navigation. Clean up first:

```javascript
document.addEventListener('turbo:before-cache', () => {
  // Close modals
  document.querySelectorAll('.modal').forEach(modal => {
    modal.classList.add('hidden');
  });

  // Clear form errors
  document.querySelectorAll('.field-error').forEach(error => {
    error.remove();
  });
});
```

### 8. Test Both Turbo and HTML Responses

Write controller tests for both:

```ruby
# spec/controllers/posts_controller_spec.rb
describe "POST #create" do
  context "with valid params" do
    it "creates a post and returns turbo_stream" do
      post :create, params: { post: valid_params }, format: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "creates a post and redirects (HTML fallback)" do
      post :create, params: { post: valid_params }
      expect(response).to redirect_to(assigns(:post))
    end
  end
end
```

### 9. Use Partials for Reusability

Partials make Turbo Streams cleaner:

```erb
<%# ✅ Good - reusable partial %>
<%= turbo_stream.append "posts", @post %>

<%# ❌ Bad - inline HTML %>
<%= turbo_stream.append "posts" do %>
  <div class="post">
    <h2><%= @post.title %></h2>
    <%# ... lots of HTML ... %>
  </div>
<% end %>
```

### 10. Broadcast Asynchronously

Don't slow down requests with broadcasts:

```ruby
# ❌ Bad - slows down the request
class Post < ApplicationRecord
  after_create_commit do
    broadcast_prepend_to "posts"
  end
end

# ✅ Better - use a job
class Post < ApplicationRecord
  after_create_commit do
    BroadcastPostJob.perform_later(self)
  end
end

# app/jobs/broadcast_post_job.rb
class BroadcastPostJob < ApplicationJob
  def perform(post)
    post.broadcast_prepend_to "posts"
  end
end
```

---

## Common Patterns

### Pattern 1: Inline Editing

**Use Case**: Edit content without leaving the page

```erb
<%# Show state %>
<turbo-frame id="<%= dom_id(@post) %>">
  <h1><%= @post.title %></h1>
  <p><%= @post.body %></p>
  <%= link_to "Edit", edit_post_path(@post) %>
</turbo-frame>

<%# Edit state (edit.html.erb) %>
<turbo-frame id="<%= dom_id(@post) %>">
  <%= form_with model: @post do |f| %>
    <%= f.text_field :title %>
    <%= f.text_area :body %>
    <%= f.submit "Save" %>
    <%= link_to "Cancel", @post %>
  <% end %>
</turbo-frame>
```

**Result**: Click "Edit" → form appears in place. Submit → content updates.
Click "Cancel" → back to show state.

### Pattern 2: Modal Forms

**Use Case**: Edit in a modal overlay

```erb
<%# In layout or page %>
<turbo-frame id="modal" data-controller="modal"></turbo-frame>

<%# Trigger link %>
<%= link_to "Edit Post", edit_post_path(@post), data: { turbo_frame: "modal" } %>

<%# edit.html.erb %>
<turbo-frame id="modal">
  <div class="modal-backdrop">
    <div class="modal-content">
      <h2>Edit Post</h2>
      <%= form_with model: @post do |f| %>
        <%= f.text_field :title %>
        <%= f.submit %>
      <% end %>
      <button data-action="modal#close">Cancel</button>
    </div>
  </div>
</turbo-frame>

<%# On successful update (update.turbo_stream.erb) %>
<%= turbo_stream.replace dom_id(@post), @post %>
<%= turbo_stream.update "modal", "" %>  <%# Clear modal %>
```

### Pattern 3: Live Search

**Use Case**: Search results update as you type

```erb
<%= form_with url: search_path,
              method: :get,
              data: {
                controller: "search",
                turbo_frame: "search_results"
              } do |f| %>
  <%= f.text_field :q,
                   data: {
                     action: "input->search#submit",
                     search_target: "input"
                   },
                   placeholder: "Search..." %>
<% end %>

<turbo-frame id="search_results">
  <%# Initial state %>
  <p>Start typing to search...</p>
</turbo-frame>

<%# search.html.erb %>
<turbo-frame id="search_results">
  <% if @results.any? %>
    <%= render @results %>
  <% else %>
    <p>No results found</p>
  <% end %>
</turbo-frame>
```

### Pattern 4: Infinite Scroll

**Use Case**: Load more content as user scrolls

```erb
<div id="posts">
  <%= render @posts %>
</div>

<% if @posts.next_page %>
  <%= turbo_frame_tag "page_#{@posts.next_page}",
                      src: posts_path(page: @posts.next_page),
                      loading: "lazy" do %>
    <div class="text-center py-4">
      <p>Loading more...</p>
    </div>
  <% end %>
<% end %>

<%# posts.html.erb (paginated page) %>
<turbo-frame id="page_<%= params[:page] %>">
  <%= render @posts %>

  <% if @posts.next_page %>
    <%= turbo_frame_tag "page_#{@posts.next_page}",
                        src: posts_path(page: @posts.next_page),
                        loading: "lazy" do %>
      <p>Loading more...</p>
    <% end %>
  <% end %>
</turbo-frame>
```

### Pattern 5: Optimistic UI

**Use Case**: Show immediate feedback before server confirmation

```erb
<%# Use Turbo's built-in loading states %>
<%= button_to "Like", like_post_path(@post),
              class: "like-button",
              data: { turbo_submits_with: "Liking..." } %>

<%# Or with CSS %>
<style>
  form[aria-busy="true"] button {
    opacity: 0.5;
    cursor: wait;
  }

  turbo-frame[busy] {
    opacity: 0.7;
  }
</style>
```

### Pattern 6: Multi-Step Forms

**Use Case**: Wizard-style forms

```erb
<%# Step 1 %>
<turbo-frame id="wizard">
  <%= form_with model: @order, url: wizard_next_path do |f| %>
    <h2>Step 1: Your Details</h2>
    <%= f.text_field :name %>
    <%= f.text_field :email %>
    <%= f.submit "Next" %>
  <% end %>
</turbo-frame>

<%# Step 2 (next.html.erb) %>
<turbo-frame id="wizard">
  <%= form_with model: @order, url: wizard_complete_path do |f| %>
    <h2>Step 2: Payment</h2>
    <%= f.text_field :card_number %>
    <%= link_to "Back", wizard_back_path, class: "button" %>
    <%= f.submit "Complete" %>
  <% end %>
</turbo-frame>
```

### Pattern 7: Toast Notifications

**Use Case**: Show temporary success/error messages

```erb
<%# In layout %>
<div id="notifications" data-controller="notification"></div>

<%# From controller or Turbo Stream %>
<%= turbo_stream.append "notifications" do %>
  <div class="notification" data-controller="notification">
    <%= message %>
  </div>
<% end %>

<%# Stimulus controller to auto-dismiss %>
import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.element.remove();
    }, 3000);
  }
}
```

---

## Troubleshooting

### Issue: Frame Not Updating

**Symptoms**: Click a link in a frame, but nothing happens

**Causes & Solutions**:

1. **Mismatched Frame IDs**

   ```erb
   <%# Source page - id="user_123" %>
   <turbo-frame id="<%= dom_id(@user) %>">
     <%= link_to "Edit", edit_user_path(@user) %>
   </turbo-frame>

   <%# Destination page - MUST match! %>
   <turbo-frame id="<%= dom_id(@user) %>">
     <%= form_with model: @user %>
   </turbo-frame>
   ```

2. **Missing Frame in Response**
   - Server returns HTML without a matching `<turbo-frame>`
   - Check the view file exists and has the right frame

3. **Frame Disabled**
   ```erb
   <%# This frame won't navigate %>
   <turbo-frame id="posts" disabled="disabled">
   ```

**Debug Tips**:

```javascript
// Check frame element
document.getElementById('your-frame-id');

// Listen to frame events
document.addEventListener('turbo:frame-missing', event => {
  console.log('Missing frame:', event.detail);
});
```

### Issue: Turbo Stream Response Displayed as Raw HTML

**Symptoms**: Instead of updating the page, the browser displays the Turbo
Stream XML as plain text (e.g., `<turbo-stream action="replace" target="...">`).

**Causes & Solutions**:

1. **Missing or Incorrect Content-Type Header**
   - The controller must respond with `Content-Type: text/vnd.turbo-stream.html`
     for Turbo.js to process the response.
   - **Cause**: Controller not using `respond_to` with `format.turbo_stream`,
     causing Rails to default to HTML.
   - **Solution**:
     ```ruby
     # ✅ Correct controller setup
     respond_to do |format|
       format.turbo_stream  # Automatically sets correct Content-Type
       format.html { redirect_to fallback_path }
     end
     ```
   - **View File**: Create `action_name.turbo_stream.erb` (e.g.,
     `toggle_like.turbo_stream.erb`) for the stream response.

2. **Form Not Sending Correct Accept Header**
   - The form must request `text/vnd.turbo-stream.html` to trigger the correct
     controller response.
   - **Solution**:
     ```erb
     <%# ✅ Add data attributes for Turbo Stream %>
     <%= button_to path, data: { turbo: true, turbo_stream: true } do %>
     ```

3. **Turbo.js Not Processing Response**
   - Ensure Turbo.js is loaded and the response is correctly formatted.
   - **Debug**: Check Network tab for `Content-Type: text/vnd.turbo-stream.html`
     and `Accept: text/vnd.turbo-stream.html`.

**Example Implementation**:

- **Controller** (`app/controllers/comments_controller.rb`):

  ```ruby
  def toggle_like
    # ... toggle logic ...
    respond_to do |format|
      format.turbo_stream  # Renders toggle_like.turbo_stream.erb
      format.html { redirect_to @guide_profile }
    end
  end
  ```

- **Turbo Stream View** (`app/views/comments/toggle_like.turbo_stream.erb`):

  ```erb
  <%= turbo_stream.replace "like_button_#{@comment.id}",
      partial: "comments/like_button",
      locals: { comment: @comment, is_liked: @is_liked } %>
  ```

- **Form** (`app/views/comments/_like_button.html.erb`):
  ```erb
  <%= button_to toggle_like_comment_path(comment),
                data: { turbo: true, turbo_stream: true } do %>
    <span><%= is_liked ? '❤️' : '🤍' %></span>
    <span><%= comment.likes_count || 0 %></span>
  <% end %>
  ```

**Debug Tips**:

```javascript
// Listen to Turbo Stream events
document.addEventListener('turbo:before-stream-render', event => {
  console.log('Stream action:', event.target.action);
  console.log('Stream target:', event.target.target);
});
```

2. **Target Element Doesn't Exist**

   ```erb
   <%# ❌ No element with id="posts" %>
   <%= turbo_stream.append "posts", @post %>

   <%# ✅ Add the container %>
   <div id="posts">
     <%= render @posts %>
   </div>
   ```

3. **Form Not Submitted with Turbo**

   ```erb
   <%# ❌ Form not submitted with Turbo %>
   <%= button_to path, method: :post do %>

   <%# ✅ Add data-turbo="true" %>
   <%= button_to path, method: :post, data: { turbo: true } do %>
   ```

4. **Response Not Reaching Client**
   - Check browser Network tab
   - Should be `Content-Type: text/vnd.turbo-stream.html`

**Debug Tips**:

```javascript
// Listen to Turbo Stream events
document.addEventListener('turbo:before-stream-render', event => {
  console.log('Stream action:', event.target.action);
  console.log('Stream target:', event.target.target);
});
```

### Issue: Form Errors Not Displaying

**Symptoms**: Invalid form submits but errors don't show

**Solution**: Return Turbo Stream with error view

```ruby
def create
  @post = Post.new(post_params)

  if @post.save
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  else
    respond_to do |format|
      format.turbo_stream do
        # Replace form with errors
        render turbo_stream: turbo_stream.replace(
          "post_form",
          partial: "posts/form",
          locals: { post: @post }  # @post has errors
        ), status: :unprocessable_entity
      end
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

### Issue: Page Caching Issues

**Symptoms**: Stale content when hitting back button

**Solution**: Clean up before caching

```javascript
document.addEventListener('turbo:before-cache', () => {
  // Hide modals
  document.querySelectorAll('.modal').forEach(el => {
    el.classList.add('hidden');
  });

  // Clear form errors
  document.querySelectorAll('.error').forEach(el => el.remove());

  // Reset forms
  document.querySelectorAll('form').forEach(form => form.reset());
});
```

### Issue: Infinite Scroll Not Working

**Symptoms**: Next page doesn't load when scrolling

**Causes & Solutions**:

1. **Missing `loading="lazy"`**

   ```erb
   <%# Frame won't lazy load without this %>
   <%= turbo_frame_tag "page_2", src: posts_path(page: 2), loading: "lazy" %>
   ```

2. **Frame Not Visible**
   - `loading="lazy"` only triggers when frame enters viewport
   - Add height to make frame visible enough to trigger

3. **Wrong Frame IDs**

   ```erb
   <%# Page 1 %>
   <%= turbo_frame_tag "page_2", src: posts_path(page: 2), loading: "lazy" %>

   <%# posts_path(page: 2) response must have: %>
   <turbo-frame id="page_2">
     <%= render @posts %>
   </turbo-frame>
   ```

### Issue: Page Scrolls to Top Due to Redirect Response

**Symptoms**: After clicking a button (e.g., like button), the page scrolls to
the top, and the update appears to work but is actually from a page reload.

**Causes & Solutions**:

1. **Controller Responding with Redirect Instead of Turbo Stream**
   - **Cause**: The controller is executing the `format.html` block instead of
     `format.turbo_stream`, often due to the request being processed as HTML
     instead of TURBO_STREAM.
   - **Debug**: Check server logs for the request. It should say "Processing by
     Controller#action as TURBO_STREAM", not "as HTML".
   - **Solution**:
     ```ruby
     # Ensure controller responds to turbo_stream format
     respond_to do |format|
       format.turbo_stream  # Renders action.turbo_stream.erb
       format.html { redirect_to fallback_path }
     end
     ```

2. **Incorrect Form Helper**
   - **Cause**: Using `link_to` or `form_with` instead of `button_to` for POST
     actions can lead to improper Turbo integration.
   - **Solution**: Use `button_to` for actions that change data, as it creates a
     proper `<form>` that Turbo can intercept reliably.
     ```erb
     <%= button_to path, data: { turbo: true } do %>
       <!-- Button content -->
     <% end %>
     ```

3. **Turbo.js Not Intercepting Form**
   - **Cause**: Turbo.js may not be intercepting the form submission correctly.
   - **Debug**: In browser Network tab, check the request:
     - Correct: Status 200 OK, Content-Type: text/vnd.turbo-stream.html
     - Incorrect: Status 302 Found (redirect), followed by a second request.
   - **Solution**: Ensure `data: { turbo: true }` is on the form and Turbo.js is
     loaded.

4. **Other Elements Triggering Reload**
   - **Cause**: Another element on the page (e.g., a form, link, or script)
     might be triggering a page reload after the DOM update.
   - **Debug**: Check if other elements are being updated or if there are event
     listeners that scroll the page.
   - **Solution**: Isolate the update by wrapping the target element in a Turbo
     Frame:
     ```erb
     <turbo-frame id="like_section_<%= comment.id %>">
       <%= render 'comments/like_button', comment: comment, is_liked: is_liked %>
     </turbo-frame>
     ```
     Then target the frame in the Turbo Stream:
     ```ruby
     turbo_stream.replace "like_section_#{@comment.id}"
     ```

**Example Implementation**:

- **Controller** (`app/controllers/comments_controller.rb`):

  ```ruby
  def toggle_like
    # ... toggle logic ...
    respond_to do |format|
      format.turbo_stream  # Renders toggle_like.turbo_stream.erb
      format.html { redirect_to @guide_profile }
    end
  end
  ```

- **View** (`app/views/comments/_like_button.html.erb`):

  ```erb
  <%= button_to toggle_like_comment_path(comment),
                class: "flex items-center gap-1 text-sm #{is_liked ? 'text-blue-600' : 'text-gray-500'} hover:text-blue-600 transition-colors cursor-pointer border-0 bg-transparent p-0",
                style: "outline: none;",
                form_class: "inline-block",
                data: { turbo: true } do %>
    <span class="inline-block transition-transform hover:scale-110">
      <%= is_liked ? '❤️' : '🤍' %>
    </span>
    <span><%= comment.likes_count || 0 %></span>
  <% end %>
  ```

- **Turbo Stream View** (`app/views/comments/toggle_like.turbo_stream.erb`):
  ```erb
  <%= turbo_stream.replace "like_button_#{@comment.id}",
      partial: "comments/like_button",
      locals: { comment: @comment, is_liked: @is_liked } %>
  ```

### Issue: Broadcasting Not Working

**Symptoms**: Real-time updates don't appear

**Causes & Solutions**:

1. **Not Subscribed**

   ```erb
   <%# Make sure this is in your view %>
   <%= turbo_stream_from @room %>
   ```

2. **Action Cable Not Running**

   ```bash
   # Check if Redis is running (needed for production)
   redis-cli ping

   # Check logs for Action Cable connection
   tail -f log/development.log | grep "ActionCable"
   ```

3. **Wrong Channel Name**

   ```ruby
   # Broadcasting to
   broadcast_append_to "room_#{room.id}"

   # But subscribed to (WRONG!)
   turbo_stream_from room  # Uses room.to_gid_param

   # Fix: be consistent
   turbo_stream_from "room_#{room.id}"
   ```

**Debug Tips**:

```javascript
// Check if Action Cable is connected
console.log(Turbo.StreamActions);

// Listen to broadcasts
document.addEventListener('turbo:before-stream-render', event => {
  console.log('Received broadcast:', event.target);
});
```

### Common Error Messages

**"Content missing"**

- The server response doesn't have a matching `<turbo-frame>` element
- Solution: Ensure the destination page has a frame with the same ID

**"Form responses must redirect to another location"**

- You're submitting a form inside a frame, but the response isn't a Turbo Stream
  or doesn't have a matching frame
- Solution: Respond with `format.turbo_stream` or include a matching frame

**"Failed to execute 'replaceChild'"**

- Trying to replace an element that doesn't exist
- Solution: Check that the target ID exists in the DOM

---

## Quick Reference

### Turbo Frame Attributes

```erb
<turbo-frame
  id="unique_id"                    # Required: unique identifier
  src="/path"                        # Optional: URL to load content from
  loading="eager|lazy"               # Optional: when to load src (default: eager)
  target="_top|_self|frame_id"      # Optional: navigation target
  data-turbo-action="advance|replace" # Optional: history behavior
  disabled                           # Optional: disable all navigation
>
```

### Turbo Stream Actions Quick Reference

```ruby
# Append to end of container
turbo_stream.append(target, partial)

# Prepend to beginning
turbo_stream.prepend(target, partial)

# Replace entire element
turbo_stream.replace(target, partial)

# Update element's contents (innerHTML)
turbo_stream.update(target, content)

# Remove element
turbo_stream.remove(target)

# Insert before element
turbo_stream.before(target, partial)

# Insert after element
turbo_stream.after(target, partial)

# Refresh the page
turbo_stream.refresh
```

### Data Attributes Quick Reference

```erb
<%# Disable Turbo for link or form %>
data-turbo="false"

<%# Target a specific frame %>
data-turbo-frame="frame_id"

<%# Navigate entire page %>
data-turbo-frame="_top"

<%# Navigate current frame %>
data-turbo-frame="_self"

<%# Update browser history %>
data-turbo-action="advance"

<%# Replace current history entry %>
data-turbo-action="replace"

<%# Confirmation dialog %>
data-turbo-confirm="Are you sure?"

<%# Custom submit button text during submission %>
data-turbo-submits-with="Saving..."

<%# Preload page on hover %>
data-turbo-preload="true"
```

### Stimulus Usage Decision Tree

```
Do I need Stimulus?
├─ Can Turbo handle it alone?
│  └─ YES → Use Turbo (preferred)
│
├─ Is it purely client-side UI state?
│  └─ YES → Use Stimulus (e.g., show/hide, modals)
│
├─ Does it involve server data?
│  └─ YES → Use Turbo (with optional Stimulus for UI polish)
│
└─ Is it a third-party library?
   └─ YES → Use Stimulus to wrap it
```

---

## Summary

**The Turbo-First Approach**:

1. **Start with Turbo Drive** - It's automatic and handles basic navigation
2. **Use Turbo Frames** - For partial page updates and independent sections
3. **Use Turbo Streams** - For surgical DOM updates and real-time features
4. **Add Stimulus Last** - Only when Turbo can't handle the interaction

**Remember**:

- HTML over the wire is simpler than JSON APIs + JavaScript
- Server-side logic is easier to test and maintain
- Turbo provides a better user experience than full page reloads
- Stimulus is for client-side polish, not core functionality

**Golden Rule**: If you're writing `fetch()` in a Stimulus controller to update
the page, you're probably doing it wrong. Use Turbo Streams instead!

---

## Additional Resources

- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction) - Official
  documentation
- [Turbo Rails Documentation](https://github.com/hotwired/turbo-rails) -
  Rails-specific helpers
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction) - For
  when you need JavaScript
- [Hotwire Discussion Forum](https://discuss.hotwired.dev/) - Community support

---

**Last Updated**: October 2025

**Questions or Improvements**: This is a living document. If you find patterns
that work well or discover better approaches, please update this guide!
