# Frontend Style Guidelines - SeeInSp

## Table of Contents

1. [Overview](#overview)
2. [Design System Architecture](#design-system-architecture)
3. [Color System](#color-system)
4. [Typography](#typography)
5. [Component Usage](#component-usage)
6. [Layout Patterns](#layout-patterns)
7. [Common Styling Issues & Fixes](#common-styling-issues--fixes)
8. [View-by-View Guidelines](#view-by-view-guidelines)
9. [Best Practices](#best-practices)
10. [Checklist for New Views](#checklist-for-new-views)

---

## Overview

SeeInSp uses a **Tailwind CSS v4 + Design System Components** architecture. This
hybrid approach combines the flexibility of Tailwind utilities with pre-built,
consistent component classes.

### Key Principles

- **Semantic**: Use meaningful color tokens (`--primary`, `--warning`) instead
  of utility colors
- **Consistent**: All similar elements should look the same across the
  application
- **Accessible**: WCAG AA compliant with proper contrast and semantic HTML
- **Responsive**: Mobile-first design with proper breakpoint handling
- **Maintainable**: Design system classes prevent style duplication

---

## Design System Architecture

### CSS Layers (Bottom → Top)

```
1. Base Layer (Tailwind reset)
   ↓
2. Component Layer (Predefined classes: .btn, .card, .form-input, etc.)
   ↓
3. Utility Layer (Tailwind utilities: text-center, flex, etc.)
   ↓
4. Theme Layer (CSS variables: var(--primary), var(--warning), etc.)
```

### File Organization

```
app/javascript/stylesheets/
├── application.css (Main entry point with imports)
├── theme.css (Primary file with CSS variables & components)
├── tailwind.css (Tailwind directives)
├── _reset.css (Base resets)
├── _elements.css (Element defaults)
├── components/
│   ├── buttons.css
│   ├── cards.css
│   ├── forms.css
│   └── status.css
└── utilities/
    └── animations.css
```

---

## Color System

### Semantic Color Tokens

Always use semantic color tokens instead of hardcoded colors:

| Purpose                | Variable             | Hex                 | Usage                          |
| ---------------------- | -------------------- | ------------------- | ------------------------------ |
| Primary Actions        | `--primary`          | `#0d9488` (teal)    | Buttons, links, primary CTAs   |
| Secondary Actions      | `--secondary`        | `#f97316` (orange)  | Alternative actions, urgency   |
| Accent (Success)       | `--accent`           | `#059669` (emerald) | Confirmations, positive states |
| Warning/Caution        | `--warning`          | `#f59e0b` (amber)   | Alerts, limited availability   |
| Danger/Destructive     | `--danger`           | `#dc2626` (red)     | Delete, cancel, error actions  |
| Info                   | `--info`             | `#3b82f6` (blue)    | Informational content          |
| Background             | `--background`       | `#fafaf9` (light)   | Page background                |
| Foreground (Text)      | `--foreground`       | `#0f172a` (dark)    | Body text                      |
| Muted (Secondary Text) | `--muted-foreground` | `#717171` (gray)    | Secondary text, hints          |

### Using Color Tokens in CSS

```css
/* ✅ DO THIS */
color: var(--primary);
background-color: var(--warning);
border-color: var(--border);

/* ❌ DON'T DO THIS */
color: #0d9488;
background-color: #f59e0b;
border-color: #e4e4e7;
```

### Tailwind Color Usage

```html
<!-- ✅ Good: Using design system through Tailwind variables -->
<button class="bg-primary text-primary-foreground">Book Now</button>

<!-- ⚠️  OK: Using Tailwind semantic colors for temporary styling -->
<div class="bg-gray-100 text-gray-700">Temporary content</div>

<!-- ❌ Bad: Hardcoding colors -->
<button style="background-color: #0d9488; color: white;">Book</button>
```

---

## Typography

### Heading Hierarchy

```html
<!-- Page Title / Main Heading -->
<h1 class="text-4xl md:text-5xl font-bold leading-tight">Page Title</h1>

<!-- Section Heading -->
<h2 class="text-3xl md:text-4xl font-bold leading-tight">Section Heading</h2>

<!-- Subsection Heading -->
<h3 class="text-xl md:text-2xl font-semibold leading-snug">
  Subsection Heading
</h3>

<!-- Small Heading -->
<h4 class="text-lg font-semibold">Small Heading</h4>
```

### Font Stack

```
Sans-serif: "Inter", "Plus Jakarta Sans", system-ui, sans-serif
Display: "Fraunces", "Recoleta", Georgia, serif
Monospace: "JetBrains Mono", "Fira Code", monospace
```

### Usage in HTML

```html
<!-- Default (sans-serif) -->
<p>Regular body text</p>

<!-- Display font for emphasis -->
<h1 class="font-display">Large Display Heading</h1>

<!-- Monospace for code -->
<code class="font-mono">function example() {}</code>
```

---

## Component Usage

### Buttons

```html
<!-- Primary Action (Most Important CTA) -->
<button class="btn-booking">Book Now</button>

<!-- Secondary Action -->
<button class="btn-booking-secondary">View Details</button>

<!-- Ghost Button (Subtle Alternative) -->
<button class="btn-booking-ghost">Learn More</button>

<!-- Small Button (In Lists/Grids) -->
<button class="btn-booking btn-sm">Quick Book</button>

<!-- Large Button (Primary CTA Area) -->
<button class="btn-booking btn-lg">Start Booking</button>

<!-- Sized Variants -->
<button class="btn-sm">Small (12px padding)</button>
<button class="btn">Default (14px padding)</button>
<button class="btn-lg">Large (16px padding)</button>

<!-- Full Width -->
<button class="btn-booking w-full">Sign In</button>

<!-- With Custom Styling (Build on Classes) -->
<button class="btn-booking flex items-center gap-2">
  <svg>...</svg>
  Book Now
</button>

<!-- ❌ Don't: Use btn-primary (use btn-booking for CTAs) -->
<!-- ❌ Don't: Hardcode button colors -->
```

### Cards

```html
<!-- Basic Card -->
<div class="card">
  <div class="card-body">
    <h3>Card Title</h3>
    <p>Card content goes here</p>
  </div>
</div>

<!-- Card with Header & Footer -->
<div class="card">
  <div class="card-header">
    <h3>Card Header</h3>
  </div>
  <div class="card-body">
    <p>Card content</p>
  </div>
  <div class="card-footer">
    <p class="text-sm text-muted-foreground">Footer info</p>
  </div>
</div>

<!-- Tour Card (Specialized) -->
<div class="tour-card">
  <% if tour.cover_image_url %>
  <div class="tour-card-image">
    <%= image_tag tour.cover_image_url, alt: tour.title, class: "w-full h-48
    object-cover" %>
    <div class="tour-card-badge">
      <span class="status-badge status-available">Available</span>
    </div>
  </div>
  <% end %>
  <div class="tour-card-content">
    <h2 class="tour-card-title"><%= tour.title %></h2>
    <p class="tour-card-description"><%= tour.description %></p>
    <div class="tour-card-meta">
      <div class="space-y-1">
        <p><strong>Location:</strong> <%= tour.location_name %></p>
        <p>
          <strong>Date:</strong> <%= tour.starts_at.strftime('%b %d, %Y') %>
        </p>
      </div>
      <div class="tour-card-price">
        <%= number_to_currency(tour.price_cents / 100.0) %>
      </div>
    </div>
    <div class="tour-card-actions">
      <%= link_to "View Details", tour, class: "btn-booking-secondary btn-sm
      flex-1 text-center" %>
    </div>
  </div>
</div>

<!-- Booking Card -->
<div class="booking-card">
  <div class="booking-card-header">
    <h3 class="booking-card-title">Booking Title</h3>
    <span class="booking-card-status booking-card-status-confirmed"
      >BOOKED</span
    >
  </div>
  <div class="booking-card-details">
    <p><strong>Date:</strong> <%= date %></p>
    <p><strong>Status:</strong> Confirmed</p>
  </div>
  <div class="booking-card-actions">
    <%= link_to "Manage", edit_booking_path(booking), class:
    "btn-booking-secondary btn-sm" %>
  </div>
</div>

<!-- Empty State Card -->
<div class="empty-state-card">
  <div class="empty-state-icon">
    <svg class="w-16 h-16"><!-- Your icon here --></svg>
  </div>
  <h3 class="empty-state-title">No items found</h3>
  <p class="empty-state-description">Start by creating something new</p>
  <div class="empty-state-action">
    <%= link_to "Create New", new_path, class: "btn-booking" %>
  </div>
</div>
```

### Forms

```html
<!-- Single Input -->
<div class="form-group">
  <%= f.label :name, class: "form-label" %> <%= f.text_field :name, class:
  "form-input" %>
</div>

<!-- Required Field -->
<div class="form-group">
  <%= f.label :email, "Email Address", class: "form-label form-label-required"
  %> <%= f.email_field :email, class: "form-input", required: true %>
</div>

<!-- Help Text -->
<div class="form-group">
  <%= f.label :spots, "Number of Spots", class: "form-label" %> <%=
  f.number_field :spots, class: "form-input" %>
  <p class="form-help">Available spots: <%= tour.available_spots %></p>
</div>

<!-- Error State -->
<div class="form-group">
  <%= f.label :password, class: "form-label" %> <%= f.password_field :password,
  class: "form-input" %> <% if resource.errors[:password].any? %>
  <p class="form-error"><%= resource.errors[:password].first %></p>
  <% end %>
</div>

<!-- Textarea -->
<div class="form-group">
  <%= f.label :description, class: "form-label" %> <%= f.text_area :description,
  rows: 5, class: "form-textarea" %>
</div>

<!-- Select Dropdown -->
<div class="form-group">
  <%= f.label :category, class: "form-label" %> <%= f.select :category, ["Option
  1", "Option 2"], {}, class: "form-select" %>
</div>

<!-- Checkbox -->
<div class="flex items-center">
  <%= f.check_box :remember_me, class: "h-4 w-4 rounded border-gray-300" %> <%=
  f.label :remember_me, "Remember me", class: "ml-2 text-sm" %>
</div>

<!-- Form Actions -->
<div class="form-actions">
  <%= f.submit "Save Changes", class: "btn-booking" %> <%= link_to "Cancel",
  back_path, class: "btn-ghost" %>
</div>

<!-- Complete Form Example -->
<%= form_with model: @tour, local: true, class: "space-y-6" do |f| %>
<div class="bg-white rounded-lg shadow-sm p-6">
  <h2 class="text-xl font-semibold mb-6">Tour Details</h2>

  <div class="form-group">
    <%= f.label :title, class: "form-label form-label-required" %> <%=
    f.text_field :title, class: "form-input", placeholder: "Enter tour title" %>
  </div>

  <div class="form-group">
    <%= f.label :description, class: "form-label form-label-required" %> <%=
    f.text_area :description, rows: 5, class: "form-textarea", placeholder:
    "Describe your tour..." %>
  </div>

  <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
    <div class="form-group">
      <%= f.label :capacity, class: "form-label form-label-required" %> <%=
      f.number_field :capacity, class: "form-input", placeholder: "Max
      participants" %>
    </div>

    <div class="form-group">
      <%= f.label :price_cents, "Price (in cents)", class: "form-label" %> <%=
      f.number_field :price_cents, class: "form-input", placeholder: "e.g.,
      10000 for $100" %>
    </div>
  </div>

  <div class="form-actions">
    <%= f.submit "Create Tour", class: "btn-booking w-full" %>
  </div>
</div>
<% end %>
```

### Status Badges

```html
<!-- Availability Status -->
<span class="status-badge status-available">Available</span>
<span class="status-badge status-limited">Limited Spots</span>
<span class="status-badge status-sold-out">Sold Out</span>

<!-- Booking Status -->
<span class="booking-card-status booking-card-status-confirmed">BOOKED</span>
<span class="booking-card-status booking-card-status-cancelled">CANCELLED</span>
<span class="booking-card-status booking-card-status-pending">PENDING</span>

<!-- Generic Badges -->
<span class="badge badge-success">Confirmed</span>
<span class="badge badge-warning">Pending</span>
<span class="badge badge-danger">Cancelled</span>
<span class="badge badge-info">Information</span>

<!-- Spot Indicators -->
<span class="spot-indicator high">12 spots</span>
<span class="spot-indicator medium">5 spots</span>
<span class="spot-indicator sold-out">Sold out</span>

<!-- Availability Indicator -->
<span class="availability-indicator">
  <span class="availability-dot high"></span>
  <span class="availability-text high">12 spots available</span>
</span>
```

### Alerts

```html
<!-- Success Alert -->
<div class="alert alert-success">
  <svg class="w-5 h-5"><!-- Success icon --></svg>
  <p>Your booking has been confirmed!</p>
</div>

<!-- Warning Alert -->
<div class="alert alert-warning">
  <svg class="w-5 h-5"><!-- Warning icon --></svg>
  <p>Limited spots available - book soon!</p>
</div>

<!-- Error Alert -->
<div class="alert alert-danger">
  <svg class="w-5 h-5"><!-- Error icon --></svg>
  <p>There was an error processing your booking.</p>
</div>

<!-- Info Alert -->
<div class="alert alert-info">
  <svg class="w-5 h-5"><!-- Info icon --></svg>
  <p>Please review your booking details before confirming.</p>
</div>

<!-- Using in Rails -->
<% flash.each do |type, message| %>
<div class="alert alert-<%= type == 'notice' ? 'success' : 'danger' %>">
  <%= message %>
</div>
<% end %>
```

---

## Layout Patterns

### Page Structure

```html
<!-- Standard Page Layout -->
<div class="min-h-screen bg-background">
  <!-- Hero/Header Section (Optional) -->
  <div
    class="bg-gradient-to-r from-primary to-secondary text-white py-12 md:py-16"
  >
    <div class="container mx-auto px-4">
      <h1 class="text-4xl md:text-5xl font-bold mb-4">Page Title</h1>
      <p class="text-lg max-w-2xl">Descriptive subtitle or tagline</p>
    </div>
  </div>

  <!-- Main Content -->
  <div class="container mx-auto px-4 py-8 md:py-12">
    <!-- Page Content -->
  </div>
</div>

<!-- Content Sections -->
<div class="container mx-auto px-4 py-8">
  <!-- Section 1 -->
  <section class="mb-12">
    <h2 class="text-3xl font-bold mb-6">Section Title</h2>
    <!-- Section content -->
  </section>

  <!-- Section 2 -->
  <section class="mb-12">
    <h2 class="text-3xl font-bold mb-6">Another Section</h2>
    <!-- Section content -->
  </section>
</div>
```

### Grid Layouts

```html
<!-- Responsive Grid (Tours, Cards, etc.) -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <!-- Cards go here -->
</div>

<!-- Two-Column Layout -->
<div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
  <div><!-- Left column --></div>
  <div><!-- Right column --></div>
</div>

<!-- Sidebar Layout -->
<div class="grid grid-cols-1 lg:grid-cols-4 gap-8">
  <div class="lg:col-span-3"><!-- Main content --></div>
  <div class="lg:col-span-1"><!-- Sidebar --></div>
</div>
```

### Spacing Classes

```html
<!-- Margins -->
<div class="mb-4">Bottom margin: 1rem</div>
<div class="mb-8">Bottom margin: 2rem</div>
<div class="mb-12">Bottom margin: 3rem</div>

<!-- Padding -->
<div class="p-4">Padding: 1rem</div>
<div class="p-6">Padding: 1.5rem</div>
<div class="p-8">Padding: 2rem</div>

<!-- Gap (Flex/Grid) -->
<div class="flex gap-4"><!-- 1rem gap --></div>
<div class="grid gap-6"><!-- 1.5rem gap --></div>

<!-- Standard Padding for Cards/Containers -->
<div class="p-4 sm:p-6">Responsive padding</div>
```

---

## Common Styling Issues & Fixes

### Issue 1: Using Custom Colors with @apply

**Problem**: Tailwind CSS v4 doesn't allow `@apply` with custom colors that use CSS variables with `<alpha-value>` placeholder. This causes build errors like "Cannot apply unknown utility class `bg-muted`" or "Cannot apply unknown utility class `ring-primary`".

**Why It Happens**: Our design system colors are defined using CSS variables with alpha channel support:
```css
/* tailwind.config.js */
colors: {
  muted: {
    DEFAULT: 'rgb(var(--muted) / <alpha-value>)',
    foreground: 'rgb(var(--muted-foreground) / <alpha-value>)'
  },
  primary: {
    DEFAULT: 'rgb(var(--primary) / <alpha-value>)',
    foreground: 'rgb(var(--primary-foreground) / <alpha-value>)'
  }
}
```

**Before (Wrong):**
```css
/* ❌ This will cause build errors */
.my-component {
  @apply bg-muted/20;
}

.my-button {
  @apply bg-primary text-primary-foreground;
}

.my-input:focus {
  @apply ring-2 ring-primary ring-offset-2;
}

.btn-secondary {
  @apply hover:bg-muted hover:border-muted;
}
```

**After (Correct):**
```css
/* ✅ Use CSS variables directly */
.my-component {
  background-color: rgb(var(--muted) / 0.2);
}

.my-button {
  background-color: rgb(var(--primary));
  color: rgb(var(--primary-foreground));
}

.my-input:focus {
  outline: 2px solid rgb(var(--primary));
  outline-offset: 2px;
}

.btn-secondary:hover {
  background-color: rgb(var(--muted));
  border-color: rgb(var(--muted));
}
```

**Key Takeaways**:
- ✅ Use `@apply` with standard Tailwind utilities (e.g., `@apply flex items-center gap-2`)
- ✅ Use CSS variables directly for custom colors (e.g., `background-color: rgb(var(--primary))`)
- ✅ For opacity, use the alpha channel in the color function (e.g., `rgb(var(--muted) / 0.2)`)
- ❌ Never use `@apply` with custom color utilities that use CSS variables
- ❌ Avoid mixing @apply with direct CSS properties for the same attribute

**Safe @apply Usage**:
```css
/* These are safe to use with @apply */
.safe-component {
  @apply flex items-center justify-between; /* ✅ Layout utilities */
  @apply rounded-lg shadow-md; /* ✅ Border/shadow utilities */
  @apply transition-all duration-200; /* ✅ Transition utilities */
  @apply px-4 py-2 mb-4; /* ✅ Spacing utilities */
  @apply text-sm font-semibold; /* ✅ Typography utilities */

  /* Use CSS variables for colors */
  background-color: rgb(var(--primary));
  color: rgb(var(--primary-foreground));
  border: 1px solid rgb(var(--border));
}
```

### Issue 2: Hardcoded Colors Instead of Design System

**Before (Wrong):**

```html
<button style="background-color: #0d9488; color: white;">Book Now</button>
<div style="background-color: #f59e0b; padding: 1rem;">Limited spots!</div>
<p style="color: #3b82f6;">Click to learn more</p>
```

**After (Correct):**

```html
<button class="btn-booking">Book Now</button>
<div class="bg-warning p-4">Limited spots!</div>
<p class="text-info">Click to learn more</p>
```

### Issue 2: Unstyled Forms

**Before (Wrong):**

```html
<h1>Create Tour</h1>
<form>
  <div class="field">
    <label>Title</label>
    <input type="text" />
  </div>
  <div class="field">
    <label>Description</label>
    <textarea></textarea>
  </div>
  <input type="submit" value="Create" />
</form>
```

**After (Correct):**

```html
<div class="min-h-screen bg-background">
  <div class="container mx-auto px-4 py-8">
    <h1 class="text-4xl font-bold mb-8">Create Tour</h1>

    <div class="bg-white rounded-lg shadow-sm p-6">
      <%= form_with model: @tour, local: true, class: "space-y-6" do |f| %>
      <div class="form-group">
        <%= f.label :title, class: "form-label form-label-required" %> <%=
        f.text_field :title, class: "form-input" %>
      </div>

      <div class="form-group">
        <%= f.label :description, class: "form-label form-label-required" %> <%=
        f.text_area :description, rows: 5, class: "form-textarea" %>
      </div>

      <div class="form-actions">
        <%= f.submit "Create Tour", class: "btn-booking w-full" %>
      </div>
      <% end %>
    </div>
  </div>
</div>
```

### Issue 3: Inconsistent Spacing

**Before (Wrong):**

```html
<div class="p-4 py-8 px-6"><!-- Conflicting padding --></div>
<div class="m-4 mb-12"><!-- Conflicting margins --></div>
```

**After (Correct):**

```html
<div class="p-6"><!-- Single padding value --></div>
<div class="mb-8"><!-- Single margin value --></div>
<div class="px-4 py-6"><!-- Responsive padding --></div>
```

### Issue 4: Inline Styles Everywhere

**Before (Wrong):**

```html
<p style="color: gray; font-size: 14px;">Muted text</p>
<div
  style="background: white; border-radius: 8px; padding: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);"
>
  Card
</div>
```

**After (Correct):**

```html
<p class="text-sm text-muted-foreground">Muted text</p>
<div class="card"><!-- Predefined card styling --></div>
```

### Issue 5: Missing Responsive Breakpoints

**Before (Wrong):**

```html
<h1 class="text-5xl">Title</h1>
<div class="grid grid-cols-3 gap-4">...</div>
```

**After (Correct):**

```html
<h1 class="text-3xl md:text-4xl lg:text-5xl">Title</h1>
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">...</div>
```

### Issue 6: Not Using Design System Classes

**Before (Wrong):**

```html
<button class="px-4 py-2 bg-orange-500 text-white rounded hover:bg-orange-600">
  Book
</button>
<a href="#" class="px-3 py-1 bg-slate-100 text-slate-900 rounded">Secondary</a>
```

**After (Correct):**

```html
<button class="btn-booking">Book</button>
<a href="#" class="btn-ghost">Secondary</a>
```

---

## View-by-View Guidelines

### Forms (tours/new.html.erb, tours/edit.html.erb)

**Status**: NEEDS MAJOR IMPROVEMENT **Issues**: No styling, raw unstyled form

**Improvements**:

- Wrap in page layout with min-h-screen and background
- Add page title with proper heading
- Group related fields
- Use form-group, form-label, form-input classes
- Add responsive grid for fields
- Add proper form actions (submit + cancel)
- Add visual hierarchy

### Authentication Views (sign_in, sign_up)

**Status**: NEEDS IMPROVEMENT **Issues**: Using hardcoded blue instead of design
system colors

**Improvements**:

- Replace hardcoded blue (#0095ff, #003366) with design system
- Use btn-booking for primary CTA
- Update input focus states to use primary color
- Improve form styling consistency

### Home Page

**Status**: PARTIALLY GOOD **Issues**: Past tours using inline gray styles,
inconsistent styling

**Improvements**:

- Replace inline gray styles with design system tokens
- Ensure all past tour cards use consistent styling
- Use design system classes throughout

### Tour Show Page

**Status**: PARTIALLY GOOD **Issues**: Mixed inline styles, inconsistent colors,
hardcoded blues

**Improvements**:

- Standardize color usage
- Replace inline styles with classes
- Ensure booking form follows guidelines

### Guide Profile Page

**Status**: NEEDS IMPROVEMENT **Issues**: Inconsistent card styling, hardcoded
colors

**Improvements**:

- Use tour-card class for all tour displays
- Standardize weather card styling
- Use design system colors throughout

### Comments & Reviews

**Status**: PARTIALLY GOOD **Issues**: Some mixed inline styles

**Improvements**:

- Ensure consistent card styling
- Use design system colors for status indicators
- Standardize spacing

---

## Best Practices

### DO ✅

1. **Use Design System Classes First**

   ```html
   <button class="btn-booking">Book Now</button>
   ```

2. **Use Semantic Color Tokens**

   ```css
   background-color: var(--primary);
   color: var(--warning);
   ```

3. **Use Responsive Breakpoints**

   ```html
   <div class="text-sm md:text-base lg:text-lg">Responsive text</div>
   ```

4. **Group Related Elements**

   ```html
   <div class="space-y-4">
     <div>Item 1</div>
     <div>Item 2</div>
   </div>
   ```

5. **Use Semantic HTML**

   ```html
   <section class="mb-12">
     <h2>Section Title</h2>
     <!-- Section content -->
   </section>
   ```

6. **Extend Components When Needed**

   ```html
   <button class="btn-booking flex items-center gap-2">
     <svg>...</svg>
     Book Now
   </button>
   ```

7. **Use Descriptive Class Names**
   ```html
   <div class="tour-card-badge">Available</div>
   <span class="booking-card-status">Confirmed</span>
   ```

### DON'T ❌

1. **Don't Use Inline Styles**

   ```html
   <!-- Bad -->
   <div style="background-color: #f59e0b; padding: 1rem;">Content</div>

   <!-- Good -->
   <div class="bg-warning p-4">Content</div>
   ```

2. **Don't Hardcode Colors**

   ```html
   <!-- Bad -->
   <button style="background-color: #0d9488;">Book</button>

   <!-- Good -->
   <button class="btn-booking">Book</button>
   ```

3. **Don't Skip Responsive Design**

   ```html
   <!-- Bad -->
   <div class="grid grid-cols-3 gap-4">...</div>

   <!-- Good -->
   <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">...</div>
   ```

4. **Don't Use Arbitrary Colors**

   ```html
   <!-- Bad -->
   <p class="text-blue-600">Text</p>

   <!-- Good -->
   <p class="text-primary">Text</p>
   ```

5. **Don't Repeat Component Markup**

   ```html
   <!-- Bad - Repeating button code -->
   <button class="px-4 py-2 bg-orange-500...">Book</button>
   <button class="px-4 py-2 bg-orange-500...">Another</button>

   <!-- Good - Use component class -->
   <button class="btn-booking">Book</button>
   <button class="btn-booking">Another</button>
   ```

6. **Don't Mix Component Approaches**

   ```html
   <!-- Bad -->
   <button class="btn-booking px-6 py-3 bg-orange-600">Book</button>

   <!-- Good -->
   <button class="btn-booking btn-lg">Book</button>
   ```

---

## Checklist for New Views

When creating a new view, follow this checklist:

### Layout & Structure

- [ ] Page has proper min-h-screen wrapper
- [ ] Background color is set (use bg-background or bg-white)
- [ ] Container uses proper mx-auto and px-4
- [ ] Content has appropriate vertical spacing (py-8, py-12)

### Typography

- [ ] Page has a clear h1 title
- [ ] Heading hierarchy is correct (h1 → h2 → h3)
- [ ] Font sizes are responsive (text-2xl md:text-3xl etc.)
- [ ] Text contrast meets WCAG AA standards

### Colors

- [ ] All colors use design system tokens (--primary, --warning, etc.)
- [ ] NO hardcoded hex colors
- [ ] Links use proper color and hover state
- [ ] Status indicators use appropriate colors

### Components

- [ ] Forms use .form-group, .form-label, .form-input
- [ ] Buttons use btn-booking or appropriate variant
- [ ] Cards use .card or specialized card classes
- [ ] Alerts use .alert with appropriate status

### Spacing

- [ ] Consistent padding (p-4, p-6, p-8)
- [ ] Consistent margins (mb-4, mb-8, mb-12)
- [ ] Grid gaps are consistent (gap-4, gap-6)
- [ ] No conflicting margin/padding classes

### Responsive Design

- [ ] Single column on mobile (grid-cols-1)
- [ ] 2-3 columns on tablet (md:grid-cols-2)
- [ ] 3+ columns on desktop (lg:grid-cols-3)
- [ ] Text scales appropriately (text-sm md:text-base)
- [ ] Spacing scales with breakpoints

### Accessibility

- [ ] Images have alt text
- [ ] Form labels are associated with inputs
- [ ] Links have descriptive text (not "click here")
- [ ] Buttons have meaningful text
- [ ] Color is not the only differentiator
- [ ] Focus states are visible

### DRY (Don't Repeat Yourself)

- [ ] Repeated component markup uses partials
- [ ] Style duplication minimized
- [ ] Extracted helper methods for complex logic
- [ ] Reusable component classes used

### Performance

- [ ] Only necessary images are loaded
- [ ] No inline script tags
- [ ] No unused CSS classes
- [ ] Proper lazy loading for images

---

## Migration Priority

### Phase 1 (Critical)

- [ ] Tour forms (new/edit) - Most visibly broken
- [ ] Authentication views - Security sensitive
- [ ] Home page - Most visible to users

### Phase 2 (Important)

- [ ] Tour show page - User-facing content
- [ ] Guide profile page - Important for discovery
- [ ] Booking management - Core functionality

### Phase 3 (Nice to Have)

- [ ] Comments & reviews
- [ ] History page
- [ ] Admin views

---

## Additional Resources

- **Design System Usage**: See DESIGN_SYSTEM_USAGE.md
- **Migration Guide**: See DESIGN_SYSTEM_MIGRATION.md
- **Style Guide**: See STYLE_GUIDE.md
- **Tailwind CSS Docs**: https://tailwindcss.com/docs
- **Component Examples**: Check DESIGN_SYSTEM_USAGE.md for detailed component
  examples

---

## Summary

The key to consistent, maintainable styling is:

1. **Always use design system classes** (.btn-booking, .card, .form-input)
2. **Use semantic color tokens** (--primary, --warning, --accent)
3. **Follow responsive design patterns** (mobile-first with breakpoints)
4. **Avoid inline styles** (use utility classes instead)
5. **Maintain proper spacing** (consistent margins and padding)
6. **Test accessibility** (contrast, keyboard navigation, semantic HTML)

When in doubt, reference existing styled views as examples and consult the
DESIGN_SYSTEM_USAGE.md guide.
