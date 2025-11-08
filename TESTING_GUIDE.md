# Testing Guide

This guide provides comprehensive documentation of the testing infrastructure for this Rails application, including factory definitions, test helpers, shared examples, and testing patterns.

## Table of Contents

1. [Test Structure](#test-structure)
2. [Factories](#factories)
3. [Test Helpers](#test-helpers)
4. [Shared Examples](#shared-examples)
5. [Testing Patterns](#testing-patterns)
6. [Running Tests](#running-tests)

## Test Structure

The test suite uses RSpec with FactoryBot, Capybara, and additional testing gems:

```
spec/
├── factories/          # FactoryBot factory definitions
├── models/            # Model unit tests
├── requests/          # Request/integration tests
├── system/            # System/feature tests (browser-based)
├── views/             # View component tests
├── policies/          # Pundit policy tests
├── services/          # Service object tests
├── jobs/              # Background job tests
└── support/           # Test helpers and shared examples
    ├── shared_examples/  # Reusable test examples
    └── *.rb              # Test configuration and helpers
```

### Test Types

- **Model specs**: Unit tests for ActiveRecord models, validations, associations, scopes
- **Request specs**: Integration tests for HTTP requests and responses
- **System specs**: End-to-end browser-based tests using Capybara
- **Policy specs**: Authorization tests using Pundit
- **Service specs**: Tests for service objects
- **Job specs**: Tests for background jobs

## Factories

Factories are defined using FactoryBot and provide convenient test data creation. All factories include schema annotations at the top showing the database structure.

### User Factory

Location: `spec/factories/users.rb`

```ruby
FactoryBot.define do
  factory :user do
    name { "Test User" }
    email { "user-#{SecureRandom.hex(5)}@example.com" }
    password { "aaaabbbbccccdddd" }
    password_confirmation { password }
    role { "tourist" }

    trait :guide do
      role { "guide" }
      name { "Guide #{SecureRandom.hex(3)}" }
    end

    trait :tourist do
      role { "tourist" }
      name { "Tourist #{SecureRandom.hex(3)}" }
    end

    trait :admin do
      role { "admin" }
      name { "Admin #{SecureRandom.hex(3)}" }
    end
  end
end
```

**Usage:**
```ruby
# Create a basic tourist user
user = create(:user)

# Create a guide user
guide = create(:user, :guide)

# Create an admin user
admin = create(:user, :admin)

# Override attributes
custom_user = create(:user, name: "Custom Name", email: "custom@example.com")
```

### Tour Factory

Location: `spec/factories/tours.rb`

```ruby
FactoryBot.define do
  factory :tour do
    guide factory: %i[user guide]  # Automatically creates a guide user
    title { "Amazing #{Faker::Adjective.positive} Tour" }
    description { Faker::Lorem.paragraph(sentence_count: 3) }
    status { :scheduled }
    capacity { 10 }
    price_cents { 5000 }
    currency { "USD" }
    location_name { Faker::Address.city }
    latitude { Faker::Address.latitude }
    longitude { Faker::Address.longitude }
    starts_at { 1.week.from_now }
    ends_at { 2.weeks.from_now }
    cover_image_url { Faker::Internet.url }
    current_headcount { 0 }

    trait :private_tour do
      tour_type { :private_tour }
      booking_deadline_hours { 24 }
    end
  end
end
```

**Usage:**
```ruby
# Create a public tour (default)
tour = create(:tour)

# Create a private tour
private_tour = create(:tour, :private_tour)

# Create with specific guide
my_guide = create(:user, :guide)
tour = create(:tour, guide: my_guide)

# Override specific attributes
tour = create(:tour, capacity: 20, price_cents: 10000)
```

### Booking Factory

Location: `spec/factories/bookings.rb`

```ruby
FactoryBot.define do
  factory :booking do
    tour
    user factory: %i[user tourist]  # Automatically creates a tourist user
    spots { 1 }
    status { :confirmed }
    booked_email { Faker::Internet.email }
    booked_name { Faker::Name.name }
    created_via { "user_portal" }
  end
end
```

**Usage:**
```ruby
# Create a booking (automatically creates tour and tourist user)
booking = create(:booking)

# Create with specific user and tour
tourist = create(:user, :tourist)
tour = create(:tour)
booking = create(:booking, user: tourist, tour: tour)

# Create with multiple spots
booking = create(:booking, spots: 3)
```

### Other Factories

- **Comment Factory** (`spec/factories/comments.rb`): Creates comments with associated user and tour
- **Like Factory** (`spec/factories/likes.rb`): Creates likes for comments
- **Review Factory** (`spec/factories/reviews.rb`): Creates reviews with rating and content
- **Tour Add-On Factory** (`spec/factories/tour_add_ons.rb`): Creates add-ons for tours
- **Booking Add-On Factory** (`spec/factories/booking_add_ons.rb`): Links add-ons to bookings
- **Email Log Factory** (`spec/factories/email_logs.rb`): Tracks email communications
- **Weather Snapshot Factory** (`spec/factories/weather_snapshots.rb`): Weather data for tours
- **Guide Profile Factory** (`spec/factories/guide_profiles.rb`): Extended guide information

## Test Helpers

### SystemHelpers

Location: `spec/support/system_helpers.rb`

Provides helpers for system/feature tests:

```ruby
module SystemHelpers
  def sign_in_user(user, password: "passwordpassword")
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: password
    click_button "Sign In"
  end
end
```

**Usage in system specs:**
```ruby
let(:user) { create(:user, :tourist) }

before do
  sign_in_user(user)
  visit tours_path
end
```

### Devise Helpers

Location: `spec/support/devise.rb`

Enables Devise test helpers for controller/request specs:

```ruby
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
end
```

**Usage:**
```ruby
# In request specs
let(:user) { create(:user, :admin) }

before do
  sign_in user
  get admin_tours_path
end
```

### FactoryBot Helpers

Location: `spec/support/factory_bot.rb`

Simplifies factory usage:

```ruby
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

This allows you to use `create`, `build`, `build_stubbed` without the `FactoryBot.` prefix.

## Shared Examples

### "an accessible page"

Location: `spec/support/shared_examples/an_accessible_page.rb`

Tests that a page meets accessibility standards (WCAG 2.0 AA).

**Usage:**
```ruby
RSpec.describe "Tour listing page" do
  let(:tour) { create(:tour) }

  before { visit tours_path }

  it_behaves_like "an accessible page"
end
```

This will automatically run:
- Axe accessibility checks for WCAG2A and WCAG2AA compliance
- Lighthouse accessibility audit

**Note:** This shared example requires `:uses_javascript` metadata, which is automatically applied.

### "a performant page"

Location: `spec/support/shared_examples/a_performant_page.rb`

Tests that a page meets performance standards using Lighthouse.

**Usage:**
```ruby
RSpec.describe "Home page" do
  before { visit root_path }

  it_behaves_like "a performant page"
end
```

This runs a Lighthouse performance audit with a minimum score of 95.

## Testing Patterns

### Model Tests

Model tests focus on validations, associations, scopes, and business logic:

```ruby
require "rails_helper"

RSpec.describe Tour do
  describe "validations" do
    subject(:tour) { build(:tour) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:capacity) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:guide) }
    it { is_expected.to have_many(:bookings) }
  end

  describe "#available_spots" do
    let(:tour) { create(:tour, capacity: 10) }

    it "calculates remaining capacity" do
      create(:booking, tour: tour, spots: 3)
      expect(tour.available_spots).to eq(7)
    end
  end
end
```

### Request Tests

Request tests verify HTTP interactions:

```ruby
require "rails_helper"

RSpec.describe "Tours" do
  let(:guide) { create(:user, :guide) }
  let(:tour) { create(:tour, guide: guide) }

  describe "GET /tours/:id" do
    it "returns successful response" do
      get tour_path(tour)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /tours" do
    context "when user is a guide" do
      before { sign_in guide }

      it "creates a new tour" do
        tour_params = attributes_for(:tour)

        expect {
          post tours_path, params: { tour: tour_params }
        }.to change(Tour, :count).by(1)
      end
    end
  end
end
```

### System Tests

System tests simulate user interactions in a browser:

```ruby
require "rails_helper"

RSpec.describe "Booking a tour" do
  let(:password) { "passwordpassword" }
  let(:tourist) { create(:user, :tourist, password: password) }
  let(:tour) { create(:tour) }

  before do
    sign_in_user(tourist, password: password)
    visit tour_path(tour)
  end

  it "allows creating a booking" do
    click_on "Book Tour"

    expect(page).to have_text("Booking was successful")
    expect(Booking.last.user).to eq(tourist)
  end

  it_behaves_like "an accessible page"
end
```

### Using Traits

Traits provide variations of factories:

```ruby
# Create different user types
admin = create(:user, :admin)
guide = create(:user, :guide)
tourist = create(:user, :tourist)

# Create different tour types
public_tour = create(:tour)  # Default is public
private_tour = create(:tour, :private_tour)
```

### Database Strategy

The test suite uses transactional fixtures by default:

```ruby
# In rails_helper.rb
config.use_transactional_fixtures = true
```

Each test runs in a database transaction that is rolled back after the test completes. This ensures test isolation.

### Test Data Best Practices

1. **Use `build` for tests that don't need database persistence:**
   ```ruby
   tour = build(:tour)
   expect(tour).to be_valid
   ```

2. **Use `create` when you need database records:**
   ```ruby
   tour = create(:tour)
   expect(Tour.count).to eq(1)
   ```

3. **Use `build_stubbed` for faster tests that only need stubbed associations:**
   ```ruby
   tour = build_stubbed(:tour)
   expect(tour.guide.name).to be_present
   ```

4. **Use `let` for lazy-loaded test data:**
   ```ruby
   let(:tour) { create(:tour) }
   let!(:booking) { create(:booking, tour: tour) }  # let! is eager-loaded
   ```

## Running Tests

### Run All Tests

```bash
bundle exec rspec
```

### Run Specific Test Files

```bash
bundle exec rspec spec/models/tour_spec.rb
bundle exec rspec spec/system/bookings_feature_spec.rb
```

### Run Tests by Type

```bash
bundle exec rspec spec/models/          # All model tests
bundle exec rspec spec/requests/        # All request tests
bundle exec rspec spec/system/          # All system tests
```

### Run Tests by Line Number

```bash
bundle exec rspec spec/models/tour_spec.rb:42
```

### Run Tests with Tags

```bash
bundle exec rspec --tag uses_javascript    # Only JavaScript tests
bundle exec rspec --tag ~uses_javascript   # Exclude JavaScript tests
```

### Run Tests with Documentation Format

```bash
bundle exec rspec --format documentation
```

### Parallel Test Execution

For faster test runs, you can use parallel_tests:

```bash
bundle exec parallel_rspec spec/
```

## Test Configuration

### Rails Helper

Location: `spec/rails_helper.rb`

Key configurations:

- Loads test environment and RSpec Rails
- Configures Capybara for system tests
- Sets up Selenium WebDriver with Chrome
- Includes test helpers and shared examples
- Configures Lighthouse and Axe matchers
- Suppresses Turbo Stream broadcasts during tests

### Browser Configuration

System tests use Chrome in headless mode by default. To run with visible browser:

```bash
HEADFUL=1 bundle exec rspec spec/system/
```

### Turbo Stream Suppression

Turbo Stream broadcasts are automatically stubbed during tests to prevent side effects:

```ruby
config.before do
  allow_any_instance_of(ActiveRecord::Base).to receive(:broadcast_prepend_to)
  allow_any_instance_of(ActiveRecord::Base).to receive(:broadcast_append_to)
  # ... other Turbo Stream methods
end
```

## Testing Tools

- **RSpec**: Testing framework
- **FactoryBot**: Test data generation
- **Capybara**: Browser simulation for system tests
- **Selenium WebDriver**: Browser automation
- **Faker**: Realistic fake data generation
- **Shoulda Matchers**: One-liner matchers for common tests
- **Pundit RSpec**: Matchers for testing Pundit policies
- **Lighthouse Matchers**: Performance and accessibility testing
- **Axe RSpec**: Accessibility testing
- **VCR**: Record and replay HTTP interactions
- **WebMock**: HTTP request stubbing
- **Timecop**: Time manipulation for tests

## Best Practices

1. **Keep tests isolated**: Each test should be independent
2. **Use descriptive test names**: Tests should read like documentation
3. **Follow AAA pattern**: Arrange, Act, Assert
4. **Test behavior, not implementation**: Focus on outcomes
5. **Use shared examples**: DRY up common test patterns
6. **Keep factories minimal**: Only set required attributes by default
7. **Use traits for variations**: Create reusable factory modifications
8. **Mock external services**: Use VCR/WebMock for API calls
9. **Test edge cases**: Include happy path, error cases, and boundary conditions
10. **Maintain test speed**: Use appropriate database strategies

## Common Issues and Solutions

### Flaky Tests

If tests fail intermittently:
- Check for timing issues in JavaScript tests
- Ensure proper `wait_for` usage in Capybara
- Verify test data is properly isolated

### Slow Tests

To improve test speed:
- Use `build` or `build_stubbed` instead of `create` when possible
- Reduce factory associations
- Use `let` instead of `before` blocks
- Consider parallel test execution

### Database Cleanup

If you encounter database state issues:
- Verify transactional fixtures are enabled
- Check for tests that disable transactions
- Review DatabaseCleaner configuration if used

---

**Last Updated**: November 2025

For questions or improvements to this guide, please create an issue or pull request.
