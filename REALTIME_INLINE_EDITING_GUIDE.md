# Real-Time Updates & Inline Editing Guide

This guide explains how the Turbo-first real-time updates and inline editing
features work in the application.

## 🎯 Features Implemented

### 1. **Inline Editing for Tour Cards**

Tour cards can now be edited inline without leaving the page or opening a modal.

#### How It Works:

**On Guide Dashboard** (`/guide_dashboard`):

- Click "Edit Inline" button on any tour card
- The card transforms into an edit form within the same Turbo Frame
- Make changes and click "Save Changes"
- The card updates instantly without page reload
- Success notification appears automatically

**On Admin Guide Profile Page** (`/admin/guide_profiles/:id`):

- Same inline editing functionality for tours
- Admins can quickly update tour details while viewing guide profiles

#### Technical Implementation:

1. **Turbo Frames** wrap each tour card:

   ```erb
   <%= turbo_frame_tag dom_id(tour) do %>
     <%= render "guides/dashboard/tour_card", tour: tour %>
   <% end %>
   ```

2. **Edit button** targets the same frame:

   ```erb
   <%= link_to "Edit Inline", edit_tour_path(tour),
               data: { turbo_frame: dom_id(tour) } %>
   ```

3. **Controller response** renders appropriate partial:
   ```ruby
   format.turbo_stream do
     render turbo_stream: turbo_stream.replace(
       dom_id(@tour),
       partial: "guides/dashboard/tour_edit_form",
       locals: { tour: @tour }
     )
   end
   ```

### 2. **Real-Time Booking Updates**

When new bookings are created or updated, tour cards automatically update across
all relevant pages.

#### What Updates in Real-Time:

- **Guide Dashboard**: Tour cards update with new booking counts, available
  spots
- **Admin Guide Profile Page**: Tour rows update with booking information
- **Capacity Indicators**: Progress bars and spot counts update automatically
- **Booking Lists**: Recent bookings section updates

#### How It Works:

1. **Turbo Stream Subscription** in views:

   ```erb
   <%= turbo_stream_from "guide_#{current_user.id}_tours" %>
   ```

2. **Model Broadcasts** when bookings change:

   ```ruby
   # In Booking model
   after_create_commit :broadcast_booking_created

   def broadcast_booking_created
     # Broadcast to guide's dashboard
     broadcast_replace_to(
       "guide_#{tour.guide_id}_tours",
       target: dom_id(tour),
       partial: "guides/dashboard/tour_card",
       locals: { tour: tour.reload }
     )
   end
   ```

3. **Tour Updates Automatically** without page reload

### 3. **Real-Time Tour Updates**

When a tour is created or updated, changes propagate to all relevant pages
instantly.

#### What Updates in Real-Time:

- **Guide Dashboard**: New tours appear automatically, updates reflect
  immediately
- **Admin Guide Profile Page**: Tour list updates in real-time
- **Admin Tours Index**: Tours list updates automatically

#### Broadcast Targets:

- `guide_#{guide_id}_tours` - Guide's personal dashboard
- `admin_guide_#{guide_id}_tours` - Admin view of specific guide
- `admin_tours` - Admin tours index page

### 4. **Visual Feedback for Updates**

Real-time updates include visual feedback to help users notice changes.

#### Flash Animation:

When content updates via Turbo Stream, a subtle flash animation highlights the
change:

- Blue glow effect
- Smooth fade in/out
- Duration: 1 second
- Respects `prefers-reduced-motion` for accessibility

#### Implementation:

```css
@keyframes flash-update {
  0% {
    background-color: rgba(59, 130, 246, 0.15);
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0.4);
  }
  100% {
    background-color: transparent;
    box-shadow: 0 0 0 0 rgba(59, 130, 246, 0);
  }
}
```

## 🏗️ Architecture

### Turbo Streams Flow

```
User Action (Create/Update Booking)
        ↓
Booking Model Callback (after_commit)
        ↓
Broadcast to Multiple Channels
        ↓
┌──────────────┬─────────────────────┬──────────────┐
│              │                     │              │
Guide          Admin Guide           Admin
Dashboard      Profile Page          Tours Index
│              │                     │              │
Tour Card      Tour Row              Tour Row
Updates        Updates               Updates
```

### Inline Editing Flow

```
Click "Edit Inline"
        ↓
Turbo Frame Request to edit_tour_path
        ↓
Controller Responds with turbo_stream format
        ↓
Renders Edit Form Partial
        ↓
Form Replaces Card in Turbo Frame
        ↓
Submit Form
        ↓
Controller Updates Tour
        ↓
Responds with Multiple Turbo Streams:
  1. Replace Frame with Updated Card
  2. Append Success Notification
        ↓
Tour Broadcasts Update to All Subscribed Pages
```

## 📁 Key Files

### Models

- `app/models/booking.rb` - Booking broadcasts
- `app/models/tour.rb` - Tour broadcasts

### Controllers

- `app/controllers/tours_controller.rb` - User tour editing
- `app/controllers/admin/tours_controller.rb` - Admin tour editing
- `app/controllers/guides/dashboard_controller.rb` - Guide dashboard

### Views

**Guide Dashboard:**

- `app/views/guides/dashboard/show.html.erb` - Main dashboard
- `app/views/guides/dashboard/_tour_card.html.erb` - Display mode
- `app/views/guides/dashboard/_tour_edit_form.html.erb` - Edit mode

**Admin Guide Profile:**

- `app/views/admin/guide_profiles/show.html.erb` - Main page
- `app/views/admin/guide_profiles/_tour_row.html.erb` - Display mode
- `app/views/admin/guide_profiles/_tour_edit_form.html.erb` - Edit mode

### JavaScript

- `app/javascript/stimulus/controllers/turbo_flash_controller.js` - Visual
  feedback
- `app/javascript/stimulus/controllers/notification_controller.js` -
  Notifications

### CSS

- `app/javascript/stylesheets/utilities/animations.css` - Flash animation
- `app/javascript/stylesheets/components/notifications.css` - Notification
  styles

## 🎨 User Experience

### For Tour Guides

1. **Dashboard View** (`/guide_dashboard`)
   - See all tours with real-time booking updates
   - Edit tours inline without leaving the page
   - Receive instant feedback when bookings are made
   - Visual flash indicates when tours update

2. **Editing Tours**
   - Click "Edit Inline" on any tour
   - Form appears in place of the card
   - Make changes and save
   - Card updates instantly with success notification

### For Admins

1. **Guide Profile View** (`/admin/guide_profiles/:id`)
   - See complete guide information
   - View all guide's tours with real-time updates
   - Edit tours inline while reviewing guide
   - Monitor booking activity in real-time

2. **Quick Updates**
   - Edit tour details without leaving guide profile
   - Changes broadcast to guide's dashboard automatically
   - Maintain context while making updates

## 🔧 Configuration

### Adding Real-Time Updates to New Features

1. **Subscribe to Turbo Streams** in your view:

   ```erb
   <%= turbo_stream_from "your_channel_name" %>
   ```

2. **Broadcast from Model**:

   ```ruby
   after_update_commit do
     broadcast_replace_to(
       "your_channel_name",
       target: dom_id(self),
       partial: "path/to/partial",
       locals: { object: self }
     )
   end
   ```

3. **Wrap Content in Turbo Frame**:
   ```erb
   <%= turbo_frame_tag dom_id(object) do %>
     <%= render "your_partial", object: object %>
   <% end %>
   ```

### Adding Inline Editing to New Components

1. **Create Display Partial** (`_object_card.html.erb`)
2. **Create Edit Partial** (`_object_edit_form.html.erb`)
3. **Add Edit Link** with `data: { turbo_frame: dom_id(object) }`
4. **Update Controller** to respond with turbo_stream format
5. **Render Appropriate Partial** based on success/failure

## 🚀 Performance Considerations

### Broadcast Efficiency

- Broadcasts are scoped to specific users/guides
- Only sends updates to subscribed channels
- Minimal payload (only updated HTML)

### Inline Editing

- No full page reloads
- Minimal JavaScript required
- Progressive enhancement (works without JS)

### Visual Feedback

- CSS-only animations
- Respects accessibility preferences
- Minimal performance impact

## 🔒 Security

- All updates require authentication
- Pundit policies enforce authorization
- CSRF tokens included in all forms
- Strong parameters prevent mass assignment

## 📊 Monitoring Real-Time Updates

To see real-time updates in action:

1. Open guide dashboard in one browser window
2. Open admin guide profile page in another window
3. Create a booking or update a tour
4. Watch both windows update automatically
5. Notice the flash animation indicating the change

## 🎯 Best Practices

1. **Always Reload Associated Data**:

   ```ruby
   locals: { tour: tour.reload }
   ```

2. **Use Specific Broadcast Channels**:

   ```ruby
   "guide_#{guide_id}_tours"  # ✅ Scoped
   "tours"                     # ❌ Too broad
   ```

3. **Provide Visual Feedback**:
   - Success notifications
   - Flash animations
   - Loading states

4. **Handle Errors Gracefully**:
   - Show error messages inline
   - Keep form data on validation errors
   - Use unprocessable_entity status

5. **Test Multiple Scenarios**:
   - Multiple users viewing same data
   - Concurrent edits
   - Network latency
   - Browser compatibility

## 🐛 Troubleshooting

**Updates not appearing in real-time?**

- Check if `turbo_stream_from` is present in the view
- Verify broadcast channel names match
- Ensure Action Cable is configured correctly
- Check browser console for WebSocket errors

**Inline editing not working?**

- Verify Turbo Frame IDs match
- Check controller responds to turbo_stream format
- Ensure partials exist and are named correctly
- Verify `data: { turbo_frame: ... }` attribute is present

**Visual flash not showing?**

- Check if CSS animations are loaded
- Verify `animate-flash-update` class is defined
- Check browser's reduced motion preferences
- Ensure animations.css is imported

## 🎓 Learning Resources

- [Turbo Handbook](https://turbo.hotwired.dev/)
- [Turbo Frames Guide](https://turbo.hotwired.dev/handbook/frames)
- [Turbo Streams Guide](https://turbo.hotwired.dev/handbook/streams)
- [Action Cable Overview](https://guides.rubyonrails.org/action_cable_overview.html)
