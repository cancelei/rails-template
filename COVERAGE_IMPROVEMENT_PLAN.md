# Test Coverage Improvement Plan

## Current Status
- **Line Coverage**: 28.86% (555/1923 lines)
- **Branch Coverage**: 26.45% (73/276 branches)
- **Target**: 80% line coverage

## Gap Analysis

### Missing Controller Tests (11 controllers need request specs)
1. `AdminController` - Main admin controller
2. `ApplicationController` - Base controller with shared logic
3. `HistoryController` - User booking history
4. `Admin::EmailLogsController` - Email log management
5. `Admin::WeatherSnapshotsController` - Weather data management
6. `Admin::UsersController` - User management (has system spec but not request spec)
7. `Guides::DashboardController` - Guide dashboard
8. `Guides::LandingController` - Guide landing page
9. `Guides::ProfileController` - Guide profile management
10. `Users::SessionsController` - Custom session handling
11. `Concerns::InlineEditable` - Inline editing concern

### Missing Job Tests (2 jobs)
1. `ReviewInviteJob` - Review invitation sender
2. `UpcomingRemindersJob` - Booking reminder sender

### Missing Model Tests (1 model)
1. `ApplicationRecord` - Base model class

### Areas to Improve Coverage
Based on common coverage gaps:
- Error handling paths in controllers
- Edge cases in model validations
- Branch coverage for conditional logic
- Helper method edge cases

## Implementation Strategy

### Phase 1: High-Impact Tests (Controllers)
Create request specs for missing controllers focusing on:
- Authentication/authorization
- Happy path scenarios
- Error responses

### Phase 2: Job Tests
Test background jobs with mocked dependencies:
- Job execution
- Email sending
- Time-based logic

### Phase 3: Expand Existing Tests
- Add edge case tests to existing specs
- Improve branch coverage
- Test error paths

### Phase 4: Integration
- Verify coverage meets 80% target
- Review and fill remaining gaps

## Estimated Coverage Gain
- Controllers: +20-25%
- Jobs: +5-8%
- Edge cases: +15-20%
- Total: ~50-53% improvement → 78-82% total coverage

## Progress Tracking

### Completed
- [x] Configure `rails test` to run RSpec via custom rake task
- [x] Identify coverage gaps and create improvement plan

### Phase 1: Controller Tests
- [ ] AdminController
- [ ] HistoryController
- [ ] Admin::EmailLogsController
- [ ] Admin::WeatherSnapshotsController
- [ ] Guides::DashboardController
- [ ] Guides::LandingController
- [ ] Guides::ProfileController
- [ ] Users::SessionsController

### Phase 2: Job Tests
- [ ] ReviewInviteJob
- [ ] UpcomingRemindersJob

### Phase 3: Coverage Verification
- [ ] Run tests and verify 80% coverage achieved
