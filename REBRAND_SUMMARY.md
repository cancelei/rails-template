# SeeInSp Rebranding Summary

## Overview

Successfully rebranded from **TourGuide** to **SeeInSp** with a strategic focus
on São Paulo, Brazil tours exclusively.

## Brand Changes

### Name

- **Old**: TourGuide
- **New**: SeeInSp (See In São Paulo)

### Positioning

- **Old**: Generic global tour platform
- **New**: Exclusive São Paulo tour platform focusing on local experiences

### Geographic Focus

All tours are now exclusively located within São Paulo metropolitan area,
featuring:

- Historic Downtown (Centro Histórico)
- Vila Madalena (Street Art District)
- Avenida Paulista
- Parque Ibirapuera
- Liberdade (Japanese District)
- Jardins
- Pinheiros
- And more São Paulo neighborhoods

## Files Updated

### Views

1. `app/views/home/index.html.erb`
   - Hero title: "Welcome to SeeInSp"
   - Tagline: "Discover amazing tours and explore São Paulo with local guides"

2. `app/views/application/_header.html.erb`
   - Logo/brand link: "SeeInSp"
   - ARIA label updated

3. `app/views/users/sessions/new.html.erb`
   - Description: "Sign in to your SeeInSp account"

### Documentation

1. `prd.md`
   - Updated product name to SeeInSp
   - Added geographic focus on São Paulo
   - Clarified non-goals exclude tours outside São Paulo

2. `STYLE_GUIDE.md`
   - Header updated to "SeeInSp"
   - Product references updated

3. `DEVELOPMENT_REFERENCE_GUIDE.md`
   - Header updated to "SeeInSp Frontend"

### Tests

1. `spec/system/accessibility/contrast_validation_spec.rb`
   - Updated test expectation for "SeeInSp" link

## New Seed Data

### User Accounts

#### Admin

- Email: `admin@seeinsp.com`
- Password: `SecurePassword123!`
- Role: Admin

#### Test User

- Email: `test@seeinsp.com`
- Password: `TestPass123!`
- Role: Tourist

### Guides (6 Total)

All guides are São Paulo locals with specialized expertise:

1. **Maria Santos** - Historical downtown tours & street art
2. **Carlos Oliveira** - Food tours & culinary experiences
3. **Ana Costa** - Art museums & cultural tours
4. **Roberto Silva** - Architecture tours
5. **Juliana Ferreira** - Nature & parks
6. **Paulo Mendes** - Music & nightlife

### Tours (15 Total)

All tours showcase different aspects of São Paulo:

#### Walking Tours

- Historic Downtown Walking Tour
- Vila Madalena Street Art Tour
- Photography Walk: São Paulo's Contrasts

#### Food Tours

- São Paulo Food Market Experience (Mercado Municipal)
- Authentic Brazilian BBQ Experience
- Coffee Culture Tour

#### Cultural Tours

- MASP & Paulista Avenue Art Walk
- Pinacoteca and São Paulo Art Scene
- Liberdade Japanese District Evening Tour

#### Nature Tours

- Ibirapuera Park Nature & Culture Tour
- Botanical Garden Discovery

#### Architecture Tours

- Modernist Architecture Tour

#### Nightlife Tours

- São Paulo Samba Night Experience

#### Active Tours

- São Paulo by Bike: City Highlights

### Realistic Data Features

- **Date Distribution**: 40% past tours, 60% future tours
- **Time Slots**: Appropriate times for each tour type (nightlife 6-8pm, food
  tours 11am-1pm, etc.)
- **Pricing**: In Brazilian Reais (BRL), ranging from R$65 to R$180
- **Capacity**: 8-15 people per tour
- **Locations**: Real São Paulo neighborhoods with actual coordinates
- **Images**: Curated Unsplash images for each tour type

### Bookings

- 10 tourist users
- Each tourist has 2-4 past tour bookings
- Each tourist has 1-2 future tour bookings
- Realistic spot reservations (1-2 spots per booking)

### Comments & Engagement

- Comments specifically mention São Paulo experiences
- Comments only from tourists who actually booked with guides
- 60% of comments have likes from other users
- Authentic engagement patterns

### Weather Data

- Fetched for tours within next 8 days
- Real São Paulo weather via OpenWeatherMap API
- Graceful error handling if API unavailable

## Environment Configuration

### Seeding Behavior

Seeds will only run in:

- ✅ Development environment (`RAILS_ENV=development`)
- ✅ Staging environment (`RAILS_ENV=staging`)
- ❌ Production environment (skipped for safety)

This allows staging deployed via Docker to automatically have meaningful São
Paulo data.

## Key Improvements

### 1. Brand Consistency

- All user-facing text updated to SeeInSp
- Consistent messaging about São Paulo focus
- Updated email addresses to @seeinsp.com domain

### 2. Geographic Focus

- All tours within São Paulo metropolitan area
- Real neighborhood names and landmarks
- Accurate GPS coordinates for each location
- Authentic local guide personas

### 3. Data Quality

- Realistic tour descriptions featuring actual São Paulo attractions
- Appropriate pricing in local currency (BRL)
- Logical time slots for different tour types
- Meaningful guide bios with local expertise

### 4. Staging Ready

- Seeds automatically populate staging database
- Production-like data for testing
- Safe idempotent seeding (can run multiple times)
- Comprehensive logging during seed process

## Testing Credentials

### Development & Staging Access

**Admin Account:**

- Email: `admin@seeinsp.com`
- Password: `SecurePassword123!`
- Access: Full admin dashboard

**Test Tourist Account:**

- Email: `test@seeinsp.com`
- Password: `TestPass123!`
- Access: Tourist features, bookings, comments

**Guide Accounts:** All guides use password: `GuidePass123!`

- maria.santos@seeinsp.com
- carlos.oliveira@seeinsp.com
- ana.costa@seeinsp.com
- roberto.silva@seeinsp.com
- juliana.ferreira@seeinsp.com
- paulo.mendes@seeinsp.com

## Next Steps

### Recommended Actions

1. ✅ Run `bin/rails db:seed` to populate development database
2. ✅ Test staging deployment with new seed data
3. ⬜ Update any marketing materials to reflect new brand
4. ⬜ Update README.md with new brand information
5. ⬜ Consider adding Brazilian Portuguese translations
6. ⬜ Add São Paulo-specific tour categories/filters
7. ⬜ Update meta tags and SEO for São Paulo focus

### Future Enhancements

- Add neighborhood-based tour filtering
- Include public transport directions from major São Paulo hubs
- Add seasonal São Paulo events calendar
- Integrate São Paulo weather patterns
- Add Portuguese language interface
- Include São Paulo tourist guide/tips section

## Migration Notes

### For Existing Data

If you have existing data in your database:

1. The seeds file uses `find_or_create_by!` for idempotent execution
2. Won't duplicate existing users/tours
3. Safe to run multiple times
4. Consider backing up before running if you have production data

### For Deployment

Docker staging environment will automatically seed on first run when
`RAILS_ENV=staging`.

## Summary

✅ **Brand**: Successfully rebranded to SeeInSp ✅ **Focus**: Exclusively São
Paulo tours ✅ **Data**: 15 realistic São Paulo tours across 6 guides ✅
**Quality**: Production-ready seed data with authentic São Paulo content ✅
**Staging**: Auto-seeds when deployed with RAILS_ENV=staging

The platform is now positioned as the go-to marketplace for discovering and
booking authentic São Paulo experiences with local guides!
