# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ============================================================================
# SEED CONFIGURATION
# ============================================================================

# Determine if we should seed (development or staging)
should_seed = Rails.env.development? || Rails.env.staging?

unless should_seed
  Rails.logger.info "Skipping seeds for #{Rails.env} environment"
  exit
end

Rails.logger.info "🌱 Seeding database for #{Rails.env} environment..."

# ============================================================================
# CLEANUP EXISTING DATA
# ============================================================================

def cleanup_existing_data
  Rails.logger.info "\n🧹 Cleaning up existing seed data..."

  # Remove existing comments and likes (they may not follow new rules)
  Like.delete_all
  Comment.delete_all
  Rails.logger.info "  ✓ Removed existing comments and likes"

  # Remove existing reviews
  Review.delete_all
  Rails.logger.info "  ✓ Removed existing reviews"

  # Remove existing booking add-ons and bookings
  BookingAddOn.delete_all
  Booking.delete_all
  Rails.logger.info "  ✓ Removed existing bookings and add-ons"

  # Remove existing weather snapshots
  WeatherSnapshot.delete_all
  Rails.logger.info "  ✓ Removed existing weather snapshots"

  # Remove existing tour add-ons
  TourAddOn.delete_all
  Rails.logger.info "  ✓ Removed existing tour add-ons"

  # Remove existing tours
  Tour.delete_all
  Rails.logger.info "  ✓ Removed existing tours"

  # Keep users and guide profiles for continuity
  Rails.logger.info "  ℹ️  Keeping existing users and guide profiles\n"
end

# ============================================================================
# HELPER METHODS
# ============================================================================

def create_admin_user
  admin = User.find_or_create_by!(email: "admin@seeinsp.com") do |user|
    user.name = "SeeInSp Admin"
    user.role = :admin
    user.password = "admin123"
  end
  Rails.logger.info "✓ Created admin user: #{admin.email}"
  admin
end

def create_guides
  guides_data = [
    {
      email: "maria.santos@seeinsp.com",
      name: "Maria Santos",
      bio: "Born and raised in São Paulo, I've been showing visitors the hidden gems of my beloved city for over 8 years. Specialized in historical downtown tours and street art.",
      languages: "Portuguese, English, Spanish"
    },
    {
      email: "carlos.oliveira@seeinsp.com",
      name: "Carlos Oliveira",
      bio: "Food enthusiast and certified sommelier. I love introducing people to São Paulo's incredible culinary scene, from traditional padarias to world-class restaurants.",
      languages: "Portuguese, English, Italian"
    },
    {
      email: "ana.costa@seeinsp.com",
      name: "Ana Costa",
      bio: "Art historian specializing in modern Brazilian art. I lead tours through São Paulo's famous museums and vibrant street art scenes in neighborhoods like Vila Madalena.",
      languages: "Portuguese, English, French"
    },
    {
      email: "roberto.silva@seeinsp.com",
      name: "Roberto Silva",
      bio: "Architecture buff with a Master's degree in Urban Planning. I showcase São Paulo's diverse architecture from modernist masterpieces to colonial churches.",
      languages: "Portuguese, English, German"
    },
    {
      email: "juliana.ferreira@seeinsp.com",
      name: "Juliana Ferreira",
      bio: "Nature lover and environmental educator. I lead eco-tours through São Paulo's parks and green spaces, including the amazing Parque Ibirapuera.",
      languages: "Portuguese, English"
    },
    {
      email: "paulo.mendes@seeinsp.com",
      name: "Paulo Mendes",
      bio: "Music and nightlife expert. I show the best of São Paulo's legendary music scene, from samba clubs to indie rock venues in Vila Madalena.",
      languages: "Portuguese, English, Japanese"
    }
  ]

  guides_data.map do |guide_data|
    user = User.find_or_create_by!(email: guide_data[:email]) do |u|
      u.name = guide_data[:name]
      u.role = :guide
      u.password = "guide123"
    end

    GuideProfile.find_or_create_by!(user:) do |profile|
      profile.bio = guide_data[:bio]
      profile.languages = guide_data[:languages]
    end

    Rails.logger.info "✓ Created guide: #{user.name}"
    user
  end
end

def create_tourists
  tourists_data = [
    { email: "alice.johnson@example.com", name: "Alice Johnson" },
    { email: "bob.smith@example.com", name: "Bob Smith" },
    { email: "carol.davis@example.com", name: "Carol Davis" },
    { email: "david.wilson@example.com", name: "David Wilson" },
    { email: "emma.brown@example.com", name: "Emma Brown" },
    { email: "frank.miller@example.com", name: "Frank Miller" },
    { email: "grace.lee@example.com", name: "Grace Lee" },
    { email: "henry.taylor@example.com", name: "Henry Taylor" },
    { email: "isabel.martinez@example.com", name: "Isabel Martinez" },
    { email: "jack.anderson@example.com", name: "Jack Anderson" }
  ]

  tourists = tourists_data.map do |tourist_data|
    User.find_or_create_by!(email: tourist_data[:email]) do |user|
      user.name = tourist_data[:name]
      user.role = :tourist
      user.password = "tourist123"
    end
  end

  Rails.logger.info "✓ Created #{tourists.count} tourist users"
  tourists
end

def create_test_user
  test_user = User.find_or_create_by!(email: "test@seeinsp.com") do |user|
    user.name = "Test User"
    user.role = :tourist
    user.password = "test123"
  end
  Rails.logger.info "✓ Created test user: #{test_user.email}"
  test_user
end

def tour_templates
  [
    # Maria Santos - Historical & Street Art Tours
    {
      guide_index: 0,
      title: "Historic Downtown Walking Tour",
      description: "Explore São Paulo's historic center, including Pateo do Collegio, São Bento Monastery, and the magnificent Teatro Municipal. Learn about the city's founding and colonial history while walking through beautifully preserved buildings and bustling streets.",
      activity_type: "walking",
      capacity: 12,
      price_cents: 8000, # R$ 80
      currency: "BRL",
      location_name: "Centro Histórico, São Paulo",
      latitude: -23.5505,
      longitude: -46.6333,
      duration: 3.hours
    },
    {
      guide_index: 0,
      title: "Vila Madalena Street Art Tour",
      description: "Discover the vibrant street art scene of Vila Madalena's famous Beco do Batman and surrounding areas. Meet local artists, learn about São Paulo's urban art movement, and capture Instagram-worthy photos of incredible murals.",
      activity_type: "walking",
      capacity: 10,
      price_cents: 7500,
      currency: "BRL",
      location_name: "Vila Madalena, São Paulo",
      latitude: -23.5467,
      longitude: -46.6892,
      duration: 2.5.hours
    },
    # Carlos Oliveira - Food Tours
    {
      guide_index: 1,
      title: "São Paulo Food Market Experience",
      description: "Taste your way through Mercado Municipal, one of São Paulo's most iconic food markets. Sample the famous mortadella sandwich, fresh fruits, artisanal cheeses, and traditional Brazilian pastries. Includes 6-8 tastings.",
      activity_type: "food",
      capacity: 8,
      price_cents: 15_000,
      currency: "BRL",
      location_name: "Mercado Municipal, Centro, São Paulo",
      latitude: -23.5413,
      longitude: -46.6298,
      duration: 3.hours
    },
    {
      guide_index: 1,
      title: "Authentic Brazilian BBQ Experience",
      description: "Discover the art of Brazilian churrasco at a traditional churrascaria. Learn about different cuts of meat, proper grilling techniques, and enjoy a full rodizio experience with caipirinha lessons included.",
      activity_type: "food",
      capacity: 12,
      price_cents: 18_000,
      currency: "BRL",
      location_name: "Jardins, São Paulo",
      latitude: -23.5683,
      longitude: -46.6640,
      duration: 3.5.hours
    },
    # Ana Costa - Art & Culture Tours
    {
      guide_index: 2,
      title: "MASP & Paulista Avenue Art Walk",
      description: "Explore São Paulo's most famous museum (MASP) and learn about Brazilian and international art. Walk down iconic Paulista Avenue, discussing the cultural significance of this vibrant area. Includes museum entrance.",
      activity_type: "cultural",
      capacity: 15,
      price_cents: 12_000,
      currency: "BRL",
      location_name: "Avenida Paulista, São Paulo",
      latitude: -23.5629,
      longitude: -46.6544,
      duration: 3.hours
    },
    {
      guide_index: 2,
      title: "Pinacoteca and São Paulo Art Scene",
      description: "Visit Pinacoteca, one of Brazil's oldest and most important art museums, housing an impressive collection of Brazilian art from the 19th century to contemporary works. Perfect for art lovers!",
      activity_type: "cultural",
      capacity: 12,
      price_cents: 10_000,
      currency: "BRL",
      location_name: "Luz, São Paulo",
      latitude: -23.5342,
      longitude: -46.6335,
      duration: 2.5.hours
    },
    # Roberto Silva - Architecture Tours
    {
      guide_index: 3,
      title: "Modernist Architecture Tour",
      description: "Discover São Paulo's incredible modernist architecture, including works by Oscar Niemeyer, Paulo Mendes da Rocha, and Lina Bo Bardi. Visit iconic buildings like the Copan Building and SESC Pompéia.",
      activity_type: "architectural",
      capacity: 10,
      price_cents: 9500,
      currency: "BRL",
      location_name: "Centro & Consolação, São Paulo",
      latitude: -23.5432,
      longitude: -46.6473,
      duration: 3.5.hours
    },
    # Juliana Ferreira - Nature Tours
    {
      guide_index: 4,
      title: "Ibirapuera Park Nature & Culture Tour",
      description: "Explore São Paulo's most famous park! Walk through beautiful gardens, visit the Ibirapuera Auditorium, the Museum of Modern Art, and learn about the park's diverse ecosystem. Perfect for nature lovers in the city.",
      activity_type: "nature",
      capacity: 15,
      price_cents: 6500,
      currency: "BRL",
      location_name: "Parque Ibirapuera, São Paulo",
      latitude: -23.5875,
      longitude: -46.6575,
      duration: 2.5.hours
    },
    {
      guide_index: 4,
      title: "Botanical Garden Discovery",
      description: "Discover over 50,000 plants at São Paulo's Botanical Garden. Learn about Brazilian native flora, see beautiful orchids, and walk through the Atlantic Forest trails. A peaceful escape from the urban jungle.",
      activity_type: "nature",
      capacity: 12,
      price_cents: 7000,
      currency: "BRL",
      location_name: "Jardim Botânico, Água Funda, São Paulo",
      latitude: -23.6411,
      longitude: -46.6283,
      duration: 2.hours
    },
    # Paulo Mendes - Music & Nightlife Tours
    {
      guide_index: 5,
      title: "São Paulo Samba Night Experience",
      description: "Experience authentic samba in São Paulo! Visit traditional samba clubs, learn basic steps, and immerse yourself in Brazilian music culture. Includes live music, drinks, and dancing lessons.",
      activity_type: "nightlife",
      capacity: 10,
      price_cents: 13_000,
      currency: "BRL",
      location_name: "Bixiga & Vila Madalena, São Paulo",
      latitude: -23.5582,
      longitude: -46.6489,
      duration: 4.hours
    },
    {
      guide_index: 5,
      title: "Liberdade Japanese District Evening Tour",
      description: "Explore São Paulo's Japanese neighborhood! Visit traditional shops, taste authentic Japanese-Brazilian fusion food, and learn about the largest Japanese community outside Japan. Evening tour includes street food tastings.",
      activity_type: "cultural",
      capacity: 12,
      price_cents: 9000,
      currency: "BRL",
      location_name: "Liberdade, São Paulo",
      latitude: -23.5582,
      longitude: -46.6334,
      duration: 3.hours
    },
    # Additional diverse tours
    {
      guide_index: 0,
      title: "Photography Walk: São Paulo's Contrasts",
      description: "Capture São Paulo's architectural and cultural contrasts through your lens. From colonial churches to modern skyscrapers, this tour is perfect for photography enthusiasts. Tips and techniques included!",
      activity_type: "photography",
      capacity: 8,
      price_cents: 8500,
      currency: "BRL",
      location_name: "Centro & Paulista, São Paulo",
      latitude: -23.5505,
      longitude: -46.6333,
      duration: 3.hours
    },
    {
      guide_index: 1,
      title: "Coffee Culture Tour",
      description: "Dive deep into São Paulo's sophisticated coffee culture. Visit specialty coffee shops, learn about Brazilian coffee production, and taste different brewing methods. For true coffee lovers!",
      activity_type: "food",
      capacity: 10,
      price_cents: 7500,
      currency: "BRL",
      location_name: "Pinheiros, São Paulo",
      latitude: -23.5626,
      longitude: -46.6927,
      duration: 2.5.hours
    },
    {
      guide_index: 3,
      title: "São Paulo by Bike: City Highlights",
      description: "Cycle through São Paulo's bike lanes and parks! See major landmarks including Paulista Avenue, Ibirapuera Park, and the Pinheiros River bike path. Bikes and safety equipment provided.",
      activity_type: "active",
      capacity: 8,
      price_cents: 9500,
      currency: "BRL",
      location_name: "Paulista to Ibirapuera, São Paulo",
      latitude: -23.5629,
      longitude: -46.6544,
      duration: 3.5.hours
    }
  ]
end

def add_on_templates_by_type
  {
    "walking" => [
      { name: "Professional Photo Package", addon_type: :photography, price_cents: 5000, pricing_type: :flat_fee, description: "Professional photographer captures your tour experience with 50+ edited digital photos" },
      { name: "Hotel Pickup (Paulista Area)", addon_type: :transportation, price_cents: 2500, pricing_type: :flat_fee, description: "Convenient pickup from hotels in the Paulista Avenue area" },
      { name: "Traditional Brazilian Snack Pack", addon_type: :food_beverage, price_cents: 1500, pricing_type: :per_person, description: "Selection of traditional Brazilian pastries and local juice" }
    ],
    "food" => [
      { name: "Wine Pairing Add-on", addon_type: :food_beverage, price_cents: 3500, pricing_type: :per_person, description: "Three glasses of carefully selected Brazilian wines to complement your food tour" },
      { name: "Premium Market Shopping Bag", addon_type: :equipment, price_cents: 800, pricing_type: :per_person, description: "Insulated shopping bag to take home your market purchases" },
      { name: "Private Transportation", addon_type: :transportation, price_cents: 8000, pricing_type: :flat_fee, description: "Private vehicle for your group between food stops" },
      { name: "Recipe Booklet", addon_type: :equipment, price_cents: 2000, pricing_type: :per_person, description: "Beautifully designed booklet with recipes from the tour" }
    ],
    "cultural" => [
      { name: "Cultural Souvenir Package", addon_type: :equipment, price_cents: 4000, pricing_type: :per_person, description: "Curated selection of local artisan crafts and cultural items" },
      { name: "Extended Tour + Lunch", addon_type: :food_beverage, price_cents: 6000, pricing_type: :per_person, description: "Continue the experience with authentic local lunch at a traditional restaurant" },
      { name: "Professional Tour Photos", addon_type: :photography, price_cents: 4500, pricing_type: :flat_fee, description: "Professional photographer documents your cultural journey" }
    ],
    "nature" => [
      { name: "Binocular Rental", addon_type: :equipment, price_cents: 1000, pricing_type: :per_person, description: "High-quality binoculars for bird watching and nature observation" },
      { name: "Picnic Lunch in the Park", addon_type: :food_beverage, price_cents: 2500, pricing_type: :per_person, description: "Gourmet picnic basket with local organic products" },
      { name: "Nature Photography Drone Footage", addon_type: :photography, price_cents: 8000, pricing_type: :flat_fee, description: "Aerial drone footage of your group's park experience" },
      { name: "Botanical Field Guide", addon_type: :equipment, price_cents: 1800, pricing_type: :per_person, description: "Illustrated guide to São Paulo's native flora" }
    ],
    "nightlife" => [
      { name: "VIP Club Entry Package", addon_type: :transportation, price_cents: 5000, pricing_type: :per_person, description: "Skip-the-line VIP entry to premium São Paulo nightclubs" },
      { name: "Premium Drink Package", addon_type: :food_beverage, price_cents: 4000, pricing_type: :per_person, description: "Four premium cocktails or caipirinhas at tour venues" },
      { name: "Late Night Snack Tour", addon_type: :food_beverage, price_cents: 2000, pricing_type: :per_person, description: "Traditional late-night São Paulo street food tasting" }
    ],
    "photography" => [
      { name: "Professional Camera Rental", addon_type: :equipment, price_cents: 6000, pricing_type: :per_person, description: "Rent a professional DSLR camera with multiple lenses for the tour" },
      { name: "Photo Editing Workshop", addon_type: :equipment, price_cents: 8000, pricing_type: :flat_fee, description: "2-hour post-tour editing workshop to enhance your photos" },
      { name: "Print Package", addon_type: :photography, price_cents: 3500, pricing_type: :per_person, description: "Five large-format prints of your best shots from the tour" }
    ],
    "active" => [
      { name: "Premium Bike Upgrade", addon_type: :equipment, price_cents: 2000, pricing_type: :per_person, description: "Upgrade to carbon-frame road bike with advanced gearing" },
      { name: "Action Camera Rental", addon_type: :photography, price_cents: 3000, pricing_type: :per_person, description: "GoPro-style camera with mounts to record your cycling adventure" },
      { name: "Post-Tour Açaí Bowl", addon_type: :food_beverage, price_cents: 1500, pricing_type: :per_person, description: "Refreshing açaí bowl at a local health café after your ride" },
      { name: "Cycling Jersey Souvenir", addon_type: :equipment, price_cents: 4500, pricing_type: :per_person, description: "Custom SeeInSp São Paulo cycling jersey to remember your tour" }
    ],
    "architectural" => [
      { name: "Architecture Guidebook", addon_type: :equipment, price_cents: 3500, pricing_type: :per_person, description: "Detailed illustrated guidebook of São Paulo's modernist architecture" },
      { name: "Building Interior Access Pass", addon_type: :transportation, price_cents: 10_000, pricing_type: :flat_fee, description: "Special access to private buildings normally closed to tourists" },
      { name: "Professional Architecture Photography", addon_type: :photography, price_cents: 6000, pricing_type: :flat_fee, description: "Professional photographer captures architectural details throughout tour" },
      { name: "Private Transport Between Buildings", addon_type: :transportation, price_cents: 7500, pricing_type: :flat_fee, description: "Comfortable vehicle transport between architectural sites" }
    ]
  }
end

def create_tours(guides)
  tours = []
  base_date = Time.current

  tour_templates.each_with_index do |template, index|
    # Distribute tours: 50% past (ended), 50% future
    days_offset = if index < (tour_templates.length * 0.5).to_i
                    # Past tours: -60 to -7 days (to ensure they're ended)
                    rand(-60..-7)
                  else
                    # Future tours: +1 to +60 days
                    rand(1..60)
                  end

    # Random time of day based on activity type
    start_hour = case template[:activity_type]
                 when "nightlife" then rand(18..20)
                 when "food" then rand(11..13)
                 else rand(9..14)
                 end

    start_time = base_date + days_offset.days + start_hour.hours
    end_time = start_time + template[:duration]

    tour = Tour.find_or_create_by!(
      title: template[:title],
      guide: guides[template[:guide_index]]
    ) do |t|
      t.description = template[:description]
      t.tour_type = :public_tour
      t.capacity = template[:capacity]
      t.price_cents = template[:price_cents]
      t.currency = template[:currency]
      t.location_name = template[:location_name]
      t.latitude = template[:latitude]
      t.longitude = template[:longitude]
      t.starts_at = start_time
      t.ends_at = end_time
    end

    # Set proper tour status based on current time
    if end_time < Time.current
      tour.update_column(:status, Tour.statuses[:done])
    elsif Time.current.between?(start_time, end_time)
      tour.update_column(:status, Tour.statuses[:ongoing])
    else
      tour.update_column(:status, Tour.statuses[:scheduled])
    end

    # Store activity type for add-on assignment
    tour.instance_variable_set(:@activity_type, template[:activity_type])

    tours << tour
    Rails.logger.info "✓ Created tour: #{tour.title} (#{tour.status})"
  end

  tours
end

def create_tour_add_ons(tours)
  Rails.logger.info "\n📦 Creating tour add-ons..."
  add_on_templates = add_on_templates_by_type

  tours.each do |tour|
    activity_type = tour.instance_variable_get(:@activity_type)
    relevant_add_ons = add_on_templates[activity_type] || add_on_templates["walking"]

    # Add 2-4 add-ons per tour
    relevant_add_ons.sample(rand(2..4)).each_with_index do |add_on_data, index|
      TourAddOn.find_or_create_by!(tour:, name: add_on_data[:name]) do |add_on|
        add_on.addon_type = add_on_data[:addon_type]
        add_on.price_cents = add_on_data[:price_cents]
        add_on.pricing_type = add_on_data[:pricing_type]
        add_on.description = add_on_data[:description]
        add_on.currency = tour.currency
        add_on.active = true
        add_on.position = index
      end
    end

    Rails.logger.info "  ✓ Added #{tour.tour_add_ons.count} add-ons to: #{tour.title}"
  end
end

def create_bookings(tours, tourists)
  Rails.logger.info "\n📅 Creating bookings..."

  # Separate tours by status
  done_tours = tours.select(&:done?)
  future_tours = tours.select { |t| t.scheduled? || t.ongoing? }

  # Each tourist books 3-5 done tours and 1-2 future tours
  tourists.each do |tourist|
    # Book completed tours
    done_tours.sample(rand(3..5)).each do |tour|
      next if Booking.exists?(tour:, user: tourist)
      next if tour.available_spots <= 0

      spots = [rand(1..2), tour.available_spots].min
      next if spots <= 0

      booking = Booking.create!(
        tour:,
        user: tourist,
        spots:,
        booked_email: tourist.email,
        booked_name: tourist.name,
        status: :confirmed
      )

      # Add add-ons to some bookings (40% chance)
      next unless tour.tour_add_ons.any? && rand < 0.4

      tour.tour_add_ons.sample(rand(1..2)).each do |tour_add_on|
        BookingAddOn.create!(
          booking:,
          tour_add_on:,
          quantity: 1,
          price_cents_at_booking: tour_add_on.price_cents
        )
      end
    end

    # Book future tours
    future_tours.sample(rand(1..2)).each do |tour|
      next if Booking.exists?(tour:, user: tourist)
      next if tour.available_spots <= 0

      spots = [rand(1..2), tour.available_spots].min
      next if spots <= 0

      booking = Booking.create!(
        tour:,
        user: tourist,
        spots:,
        booked_email: tourist.email,
        booked_name: tourist.name,
        status: :confirmed
      )

      # Add add-ons to some bookings (40% chance)
      next unless tour.tour_add_ons.any? && rand < 0.4

      tour.tour_add_ons.sample(rand(1..2)).each do |tour_add_on|
        BookingAddOn.create!(
          booking:,
          tour_add_on:,
          quantity: 1,
          price_cents_at_booking: tour_add_on.price_cents
        )
      end
    end
  end

  Rails.logger.info "✓ Created #{Booking.count} bookings"
end

def create_reviews(tours)
  Rails.logger.info "\n⭐ Creating reviews..."

  review_texts = [
    "Absolutely amazing experience! The guide was knowledgeable and passionate about São Paulo.",
    "One of the best tours I've ever taken. Highly recommended!",
    "Great tour with excellent insights into São Paulo's culture and history.",
    "The guide made the experience unforgettable. Would definitely book again!",
    "Fantastic tour! Learned so much and had a wonderful time.",
    "Very informative and well-organized tour. The guide was professional and friendly.",
    "Exceeded my expectations! São Paulo is incredible and this tour showed the best of it.",
    "Wonderful experience exploring São Paulo with such a knowledgeable guide.",
    "Perfect introduction to the city! The guide's passion really showed through.",
    "Great value for money. Highly recommend this tour to anyone visiting São Paulo!"
  ]

  # Add reviews to 50% of completed tour bookings
  done_tours = tours.select(&:done?)
  done_tours.each do |tour|
    tour.bookings.confirmed.sample((tour.bookings.confirmed.count * 0.5).to_i).each do |booking|
      next if booking.review.present?

      Review.create!(
        booking:,
        tour:,
        user: booking.user,
        rating: rand(3..5), # Ratings between 3-5 stars
        comment: review_texts.sample
      )
    end
  end

  Rails.logger.info "✓ Created #{Review.count} reviews"
end

def create_comments_and_likes(guides, _all_tourists)
  Rails.logger.info "\n💬 Creating comments..."

  sp_comments = [
    "Absolutely loved exploring São Paulo with this guide! Their local knowledge made all the difference.",
    "Best tour I've taken in SP! The guide's passion for the city really showed through.",
    "Highly recommend for anyone visiting São Paulo. Got to see sides of the city I never would have found alone.",
    "Amazing experience! The guide knew all the best spots and shared fascinating stories about São Paulo's history.",
    "Perfect introduction to São Paulo! Professional, knowledgeable, and fun.",
    "This tour exceeded my expectations! São Paulo is incredible and this guide knows it inside out.",
    "Fantastic tour! The guide's enthusiasm for São Paulo was contagious.",
    "Great way to explore São Paulo! Would definitely book again on my next visit.",
    "Informative and engaging tour. Learned so much about São Paulo's culture and history.",
    "The guide's local insights made this tour special. Best way to see the real São Paulo!"
  ]

  guides.each do |guide|
    # Get tourists who have ENDED tours with this guide
    tourists_with_ended_tours = User.joins(:bookings)
                                    .joins("INNER JOIN tours ON tours.id = bookings.tour_id")
                                    .where(role: :tourist)
                                    .where(bookings: { status: :confirmed })
                                    .where(tours: { guide_id: guide.id, status: :done })
                                    .distinct

    # Create comments from 30-60% of eligible tourists
    sample_size = [tourists_with_ended_tours.count, (tourists_with_ended_tours.count * rand(0.3..0.6)).to_i].min
    next if sample_size.zero?

    tourists_with_ended_tours.sample(sample_size).each do |tourist|
      comment = Comment.find_or_create_by!(user: tourist, guide_profile: guide.guide_profile) do |c|
        c.content = sp_comments.sample
      end

      # Add likes to comments (40-80% of comments get likes)
      next unless rand < rand(0.4..0.8)

      # Only tourists who have also had ended tours with this guide can like
      potential_likers = tourists_with_ended_tours.where.not(id: tourist.id)

      # Each comment gets 1-5 likes
      potential_likers.sample([potential_likers.count, rand(1..5)].min).each do |liker|
        Like.find_or_create_by!(user: liker, comment:)
      end
    end
  end

  Rails.logger.info "✓ Created #{Comment.count} comments with #{Like.count} likes"
end

def fetch_weather_data(tours)
  Rails.logger.info "\n🌤️  Fetching weather data..."

  upcoming_tours = tours.select { |t| t.starts_at.between?(Time.current, 8.days.from_now) }
  upcoming_tours.each do |tour|
    next unless tour.latitude && tour.longitude

    begin
      forecasts = WeatherService.fetch_forecast(tour.latitude, tour.longitude)
      forecasts.each do |forecast|
        WeatherSnapshot.find_or_create_by!(tour:, forecast_date: forecast[:forecast_date]) do |snapshot|
          snapshot.min_temp = forecast[:min_temp]
          snapshot.max_temp = forecast[:max_temp]
          snapshot.description = forecast[:description]
          snapshot.icon = forecast[:icon]
          snapshot.pop = forecast[:pop]
          snapshot.wind_speed = forecast[:wind_speed]
        end
      end
      Rails.logger.info "✓ Fetched weather for: #{tour.title}"
    rescue StandardError => e
      Rails.logger.warn "⚠ Could not fetch weather for #{tour.title}: #{e.message}"
    end
  end
end

def print_summary(tours)
  done_tours = tours.select(&:done?)
  scheduled_tours = tours.select(&:scheduled?)
  ongoing_tours = tours.select(&:ongoing?)

  Rails.logger.info "\n#{"=" * 70}"
  Rails.logger.info "🎉 SEED DATA CREATED SUCCESSFULLY!"
  Rails.logger.info "=" * 70
  Rails.logger.info "\n📊 Summary:"
  Rails.logger.info "   Environment: #{Rails.env}"
  Rails.logger.info "   Admins: #{User.where(role: :admin).count}"
  Rails.logger.info "   Guides: #{User.where(role: :guide).count}"
  Rails.logger.info "   Tourists: #{User.where(role: :tourist).count}"
  Rails.logger.info "   Tours: #{Tour.count} total"
  Rails.logger.info "     - Done: #{done_tours.count}"
  Rails.logger.info "     - Ongoing: #{ongoing_tours.count}"
  Rails.logger.info "     - Scheduled: #{scheduled_tours.count}"
  Rails.logger.info "   Tour Add-ons: #{TourAddOn.count}"
  Rails.logger.info "   Bookings: #{Booking.count}"
  Rails.logger.info "   Booking Add-ons: #{BookingAddOn.count}"
  Rails.logger.info "   Reviews: #{Review.count}"
  Rails.logger.info "   Comments: #{Comment.count} (only from tourists with ended tours)"
  Rails.logger.info "   Likes: #{Like.count} (only from tourists with ended tours)"
  Rails.logger.info "   Weather Snapshots: #{WeatherSnapshot.count}"

  Rails.logger.info "\n🔐 Test Credentials:"
  Rails.logger.info "   Admin:"
  Rails.logger.info "     Email: admin@seeinsp.com"
  Rails.logger.info "     Password: admin123"
  Rails.logger.info "\n   Test User (Tourist):"
  Rails.logger.info "     Email: test@seeinsp.com"
  Rails.logger.info "     Password: test123"
  Rails.logger.info "\n   Any Guide:"
  Rails.logger.info "     Email: maria.santos@seeinsp.com (or any other guide email)"
  Rails.logger.info "     Password: guide123"
  Rails.logger.info "\n   Any Tourist:"
  Rails.logger.info "     Email: alice.johnson@example.com (or any other tourist email)"
  Rails.logger.info "     Password: tourist123"

  Rails.logger.info "\n🗺️  All tours are located in São Paulo, Brazil"
  Rails.logger.info "   Historic Downtown, Vila Madalena, Paulista, Ibirapuera,"
  Rails.logger.info "   Liberdade, Jardins, Pinheiros, and more!"

  Rails.logger.info "\n💡 Important Notes:"
  Rails.logger.info "   - Comments only created from tourists who completed tours with guides"
  Rails.logger.info "   - Likes only from tourists who also completed tours with those guides"
  Rails.logger.info "   - ~40% of bookings include add-ons"
  Rails.logger.info "   - ~50% of completed tour bookings have reviews"

  Rails.logger.info "\n#{"=" * 70}"
end

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Cleanup existing seed data to ensure data integrity
cleanup_existing_data

# Create users
create_admin_user
guides = create_guides
tourists = create_tourists
test_user = create_test_user

# Create tours and related data
tours = create_tours(guides)
create_tour_add_ons(tours)

# Create bookings and interactions
all_tourists = tourists + [test_user]
create_bookings(tours, all_tourists)
create_reviews(tours)
create_comments_and_likes(guides, all_tourists)

# Fetch weather data
fetch_weather_data(tours)

# Print summary
print_summary(tours)
