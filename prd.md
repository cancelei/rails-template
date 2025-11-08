# PRD v1 — SeeInSp MVP (AI-Agents Friendly)

## 1) Product Summary & Goals

A lightweight platform exclusively for tours in **São Paulo, Brazil**, where:

- **Guides** create/manage tours across São Paulo's neighborhoods and
  attractions.
- **Tourists** can **book without an account**; a user record is auto-created
  post-booking.
- **Reviews**: 0–5 stars + optional comment (≤1000 chars) after the tour is
  **done**.
- **Status tracking** per tour: `scheduled | ongoing | done | cancelled`.
- **Weather**: Track **daily 8-day forecast** for São Paulo tours via
  **OpenWeatherMap API v2.5**.
- **Emails**: Transactional notifications via **EMAILIT** (with testing &
  delivery verification).
- **Admin** (via Pundit) can **CRUD everything** and see guide/tourist counts.
- **Geographic Focus**: All tours must be located within São Paulo metropolitan
  area.

Non-goals for MVP: payments, complex pricing, multi-currency, multi-tenant orgs,
tours outside São Paulo.

---

## 2) Core User Stories

- As a **Guide**, I can create/edit a tour with title, description, price
  (optional), capacity, dates, meeting point (lat/lon), and images.
- As a **Tourist**, I can book a spot **without logging in**; after booking I’m
  emailed a magic link to manage my booking.
- As a **Tourist**, after the tour is **done**, I can submit **one** review (0–5
  stars, ≤1000 chars).
- As an **Admin**, I can view counts of guides, tourists, tours, bookings;
  filter by status; and **CRUD** all records.
- As a **System**, I track and refresh 8-day daily forecasts for upcoming tours;
  I email tourists reminders.

---

## 3) Entities & Data Model (MVP)

**User**

- id, name, email (uniq), role (`tourist|guide|admin`), phone (opt), created_at
- auth: passwordless magic link (token + expiry), last_login_at

**GuideProfile**

- id, user_id (FK, role=guide), bio, languages, rating_cached (float),
  created_at

**Tour**

- id, guide_id (FK), title, description (rich text OK), status (enum), capacity,
  price_cents (opt), currency (opt)
- location_name, latitude, longitude, starts_at (tz aware), ends_at (tz aware),
  cover_image_url (opt)
- current_headcount (denormalized), created_at

**Booking**

- id, tour_id (FK), user_id (FK, role=tourist), spots (default 1), status
  (`confirmed|cancelled`)
- booked_email (copy of email at booking), booked_name
- created_via (`guest_booking|user_portal`), created_at

**Review**

- id, booking_id (FK), tour_id (FK), user_id (FK)
- rating (int 0..5), comment (≤1000), created_at
- constraints: **one review per booking**; only allowed when tour.status=`done`.

**WeatherSnapshot**

- id, tour_id (FK), forecast_date (date), min_temp, max_temp, description, icon,
  pop (prob. of precip), wind_speed, alerts_json (opt)
- source: openweathermap v2.5
- unique: (tour_id, forecast_date)

**EmailLog**

- id, to, subject, template, payload_json, provider_message_id, status
  (`sent|failed|sandbox`), created_at

---

## 4) Status Lifecycle & Rules

**Tour.status**

- `scheduled` → may transition to `ongoing` (at starts_at) or `cancelled`.
- `ongoing` → auto to `done` at ends_at (job), or manual `cancelled` (edge
  case).
- `done` → immutable (except Admin).
- `cancelled` → immutable (except Admin). **Booking.status**
- default `confirmed`; can be `cancelled` manually by guide/admin or by tourist
  via portal (MVP optional).

Guards:

- When `cancelled`, notify all tourists.
- When `done`, **open review window** (e.g., 14 days).

---

## 5) Integrations

**EMAILIT**

- Use for: booking confirmation, magic link login, reminders (T-72h & T-24h),
  status changes, review invitation, cancellation.
- Testing: sandbox key + forced “test mode” toggle; record to **EmailLog** with
  provider ids and delivery status check endpoint.

**OpenWeatherMap v2.5**

- Endpoint: One Call (v2.5) daily forecast (8 days). Inputs: lat, lon;
  units=metric; lang configurable later.
- Fetch policy:
  - On **tour creation**: seed 8-day snapshots if tour starts within 8 days.
  - Nightly job: refresh snapshots for all tours **starting within next 8
    days**.
  - If tour is >8 days out, begin collection when T-8 <= today.

- Store min/max temp, description, icon, pop, wind; keep last value per (tour,
  date).

---

## 6) Permissions (Pundit)

- **Admin**: full CRUD on all models; access to metrics dashboard.
- **Guide**: CRUD only their own tours; view own bookings & reviews; can mark
  tour `cancelled`.
- **Tourist**: create bookings; manage own bookings; create a review tied to
  their booking when tour is `done`.
- Unauthenticated: browse tours, book a tour (guest flow).

---

## 7) UX / Pages

**Homepage**

- Hero + search (location/date), featured tours, categories (optional), CTA
  “Create a Tour” (guides).
- Cards show: title, guide name, dates, location, short desc, status badge,
  rating avg, price (opt).
- Weather badge (if within 8 days): next upcoming day’s summary.

**Tour Detail**

- Title, images, description, guide profile, dates, meeting point map, remaining
  spots, status.
- **Book Now** form (name, email, phone opt, spots). No login required.
- Weather tab (8-day forecast tiles if available).

**Booking Confirmation**

- Success page with booking details; **email magic link** sent to manage
  booking.

**Review Form**

- Accessible from magic link & user portal after `done`. 0–5 star input +
  comment (≤1000).

**Guide Dashboard**

- List of my tours with status, headcount; quick actions (edit, cancel, mark as
  ongoing/done).

**Admin Dashboard**

- KPIs: #Guides, #Tourists, #Active Tours, #Upcoming Tours, #Bookings last 7/30
  days.
- Tables with filters; global CRUD.

---

## 8) Flows (Happy Paths)

**Guest Booking → User Auto-Create**

1. Tourist submits name, email, spots on Tour Detail.
2. Create **User**(role=tourist) if not exists.
3. Create **Booking**(confirmed). Increment tour headcount (guard ≤ capacity).
4. Send **Booking Confirmation** + **Magic Link** (EMAILIT).
5. Log to **EmailLog**.

**Review**

1. Scheduler marks tour `done`.
2. Send **Review Invitation**.
3. Tourist opens magic link → submits rating/comment (validate). One review per
   booking.

**Weather**

1. On creation or nightly job: call OWM v2.5 for tours within 8 days.
2. Upsert **WeatherSnapshot** per forecast day.

**Email Reminders**

- T-72h and T-24h before `starts_at`: send reminder (include weather summary if
  present).
- On `cancelled`: send cancellation email immediately.

---

## 9) API / Endpoints (REST, minimal)

- `GET /tours` (filters: location, date_range, status)
- `GET /tours/:id`
- `POST /tours` (guide)
- `PATCH /tours/:id` (owner guide | admin)
- `POST /tours/:id/bookings` (guest ok)
- `GET /bookings/:token` (magic-link)
- `POST /bookings/:token/cancel` (opt in MVP)
- `POST /bookings/:token/review`
- `GET /admin/metrics` (admin)
- Internal jobs: `/jobs/refresh_weather`, `/jobs/roll_status` (not public)

---

## 10) Emails (Templates)

- Booking Confirmation (tour info, manage link)
- Magic Link Login
- Reminder 72h / 24h (itinerary + weather summary)
- Status Change: Cancelled
- Review Invitation (after done)
- Email test mode report (admin-only)

---

## 11) Acceptance Criteria (Samples)

- Booking possible without prior account. ✅ A **User** is created automatically
  and linked to the **Booking**.
- Review requires `tour.status=done`, rating in **[0..5]**, comment length
  ≤1000, one per booking.
- Tour status auto-rolls based on time; transitions logged.
- WeatherSnapshots exist for tours starting within 8 days; nightly refresh runs
  and updates values.
- EMAILIT logs every send; admin can see last 50 deliveries with provider ids
  and statuses.
- Admin can CRUD all entities; dashboard shows counts that match DB truth.

---

## 12) Ops & Scheduled Jobs

- `RollTourStatusJob` (every 15 min): scheduled→ongoing at `starts_at`;
  ongoing→done at `ends_at`.
- `RefreshWeatherJob` (daily 01:00 local): fetch/update 8-day forecasts for
  tours within window.
- `UpcomingRemindersJob` (hourly): send T-72h/T-24h reminders.
- `ReviewInviteJob` (hourly): for tours transitioned to `done`.

---

## 13) Observability & QA

- Structured logs for email sends, weather fetches (lat, lon, tour_id, rate
  limits).
- Feature flags: `emailit.sandbox`, `bookings.allow_guest`.
- Seed data: 2 guides, 6 tours (varied dates), 10 bookings, 3 reviews, 1 admin.
- Email test harness: toggle sandbox → send to fixed test mailbox; verify
  provider webhook or polling endpoint; assert **EmailLog.status**.

---

## 14) Security & Privacy (MVP)

- Magic links: single-use tokens, 30-min TTL (configurable).
- PII: store only needed fields (name, email, phone optional).
- Rate-limit booking and review endpoints by IP + email.

---

## 15) Assumptions

- Single currency display is acceptable for MVP.
- No payments in MVP.
- One guide owns each tour (no co-hosts).
- OpenWeatherMap Developer plan quota is sufficient for nightly calls.

---

## 16) Stretch (Post-MVP, not required now)

- Payments & refunds, calendar sync, multi-day itineraries, i18n, guide
  verification, richer review moderation, weather alerts pushed on severe
  changes.
