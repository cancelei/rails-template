# Admin Quick Start Guide

## Quick Reference for Admin Users

### 🎯 What Can Admins Do?

As an admin, you can **edit any content directly in the public views** without navigating to separate admin pages. This includes:

- ✅ Tour details (title, description, dates, pricing, etc.)
- ✅ Guide profiles (bio, languages, ratings)
- ✅ Bookings (status, spots, notes)
- ✅ Reviews and ratings
- ✅ User information
- ✅ Tour add-ons

---

## 🚀 Quick Actions

### Editing a Tour

1. Go to any tour page: `/tours/:id`
2. Hover over the "Tour Details" card
3. Click the **Edit** button (top-right)
4. Make your changes
5. Click **Save Changes**

**Keyboard Shortcut:** `Ctrl+E` (or `Cmd+E` on Mac) while hovering

### Editing a Guide Profile

1. Go to any guide profile: `/guide_profiles/:id`
2. Hover over the profile section
3. Click **Edit**
4. Update bio, languages, or other fields
5. Save your changes

### Helping New Guides

**Common tasks:**

1. **Improve tour descriptions**
   - Navigate to the guide's tour
   - Click Edit
   - Enhance title and description
   - Add missing details (location, pricing)

2. **Complete profile information**
   - Visit guide profile
   - Click Edit
   - Fill in bio if missing
   - Add languages spoken

3. **Fix pricing or availability**
   - Go to tour page
   - Edit tour details
   - Update price, capacity, or tour type

---

## 🎨 Visual Indicators

When logged in as admin, you'll see:

| Indicator | Meaning |
|-----------|---------|
| Edit button on hover | Content is editable |
| Blue border on hover | Section can be modified |
| "Admin" badge | Admin-only editable area |

---

## 🔐 Permission Levels

### Admin (You)
- ✅ Edit **any** tour, profile, booking
- ✅ Manage users
- ✅ View all analytics
- ✅ Access admin dashboard

### Guide
- ✅ Edit **own** profile
- ✅ Manage **own** tours
- ✅ View bookings for **their** tours
- ❌ Cannot edit other guides' content

### Tourist
- ✅ Manage **own** bookings
- ✅ Leave reviews on completed tours
- ❌ Cannot edit tours or profiles

---

## 💡 Tips & Tricks

### 1. Use Keyboard Shortcuts

- **Edit**: `Ctrl+E` or `Cmd+E` (while hovering over editable content)
- **Cancel**: `ESC` (while in edit mode)

### 2. Batch Editing

If you need to edit multiple tours:
1. Open each tour in a new tab
2. Edit inline without losing your place
3. Changes save immediately via Turbo

### 3. Mobile Editing

On mobile devices:
- Edit buttons are always visible (no need to hover)
- Forms are touch-optimized
- Same functionality as desktop

### 4. Context Awareness

The system knows where you're editing from:
- Edits from tour page → Returns to tour view
- Edits from admin dashboard → Returns to dashboard
- No navigation confusion!

---

## 🛠️ Common Scenarios

### Scenario 1: New Guide Needs Help

**Problem:** Guide created a tour but description is unclear

**Solution:**
1. Navigate to their tour
2. Click Edit on "Tour Details"
3. Improve description, add location details
4. Save changes
5. (Optional) Message guide about best practices

### Scenario 2: Incorrect Pricing

**Problem:** Tour price is wrong

**Solution:**
1. Go to tour page
2. Edit tour details
3. Update `price_cents` field
4. Verify currency is correct
5. Save

### Scenario 3: Profile Information Missing

**Problem:** Guide profile lacks bio or languages

**Solution:**
1. Visit guide profile page
2. Click Edit on profile section
3. Add bio and languages
4. Save changes

---

## 📊 Admin Dashboard vs Inline Editing

### When to use Admin Dashboard (`/admin`)

- Viewing system-wide metrics
- Managing users in bulk
- Accessing email logs
- Viewing all bookings across tours

### When to use Inline Editing

- Helping a specific guide
- Fixing content on public pages
- Quick edits while browsing
- Teaching new guides

**Both work together!** Use whichever is more convenient.

---

## ⚠️ Important Notes

### 1. Changes are Immediate

- No "draft" mode
- Edits go live instantly
- Users will see changes right away

### 2. Edit History

- Currently no edit history tracking
- Be careful when making changes
- Consider taking notes of major changes

### 3. Validation Rules Still Apply

- Cannot set negative prices
- Cannot set capacity to 0
- Dates must be valid
- Required fields must be filled

### 4. Authorization is Enforced

- Even as admin, you must be logged in
- Sessions expire after inactivity
- Use strong passwords

---

## 🐛 Troubleshooting

### "Edit button doesn't appear"

- ✓ Verify you're logged in as admin
- ✓ Check if you're viewing the right resource
- ✓ Try refreshing the page

### "Changes don't save"

- ✓ Check for validation errors (shown in red)
- ✓ Ensure required fields are filled
- ✓ Check browser console for JavaScript errors

### "Form looks broken"

- ✓ Try hard refresh (`Ctrl+Shift+R`)
- ✓ Clear browser cache
- ✓ Try different browser

### "Cannot edit specific field"

- ✓ Some fields may be read-only (e.g., timestamps)
- ✓ Check if field is included in form
- ✓ Verify strong parameters allow the field

---

## 🎓 Best Practices

### DO ✅

- ✅ Make incremental changes
- ✅ Test changes in preview (if available)
- ✅ Use clear, descriptive text
- ✅ Follow existing content patterns
- ✅ Keep accessibility in mind

### DON'T ❌

- ❌ Delete content without checking usage
- ❌ Change prices during active bookings
- ❌ Edit multiple tours simultaneously (to avoid confusion)
- ❌ Remove required information
- ❌ Use special characters that might break formatting

---

## 📞 Need Help?

If you encounter issues:

1. Check this guide first
2. Review the [Full Admin Inline Editing Guide](ADMIN_INLINE_EDITING_GUIDE.md)
3. Check application logs (if you have access)
4. Contact technical support

---

## 🔄 Workflow Example

**Goal:** Help a new guide improve their first tour

```
1. Browse to guide's profile
   → /guide_profiles/123

2. Review their tours
   → Click on incomplete tour

3. Edit tour inline
   → Hover → Click Edit → Make changes → Save

4. Return to profile
   → Edit profile bio → Save

5. Done!
   → Guide's content is now professional
```

**Time saved:** ~10 minutes vs navigating admin panels

---

## 📈 Impact Metrics

### Before Inline Editing
- Navigate to admin panel
- Find resource in list
- Click edit link
- Make changes
- Navigate back to context
- **~5-7 clicks, 30+ seconds**

### With Inline Editing
- Hover over content
- Click edit
- Make changes
- **~2-3 clicks, 10 seconds**

**Productivity gain: 60-70%**

---

## 🎉 Summary

The inline editing system empowers you to:
- **Help guides faster**
- **Fix issues immediately**
- **Stay in context**
- **Teach by example**

No more admin panel navigation. Just hover, edit, save!

**Remember:** With great power comes great responsibility. Edit wisely! 🦸
