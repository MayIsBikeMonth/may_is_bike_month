# May is Bike Month Rails Application

May is Bike Month is a Ruby on Rails application for tracking cycling competition scores and leaderboards. It integrates with Strava to pull activity data and displays results for monthly cycling competitions.

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Critical Setup Requirements

### System Dependencies
- **Ruby 3.4.3** (specified in .tool-versions)
- **Node.js 20.17.0** (specified in .tool-versions)
- **PostgreSQL** (database)
- **Redis** (for background job processing with Sidekiq)

### Docker Development Environment
The application is designed to work with Docker containers for PostgreSQL and Redis. The CI configuration (`.github/workflows/`) shows the expected setup:
- PostgreSQL: `postgres:17-alpine` on port 5432 with user `rails`, password `password`
- Redis: `redis` on port 6379

## Bootstrap and Build Process

**NEVER CANCEL: All commands below have been timed and tested. Wait for completion.**

### Initial Setup (run once)
```bash
# Install Ruby dependencies - takes ~45 seconds on fresh setup, ~1 second if cached
bundle install

# Install Node.js dependencies - takes ~1-2 seconds
yarn install

# Copy environment template and configure
cp .env.template .env
```

### Environment Configuration
Update `.env` file with proper values:
```env
STRAVA_CLIENT_ID=test_client_id
STRAVA_SECRET=test_secret
DEVISE_SECRET_KEY=89abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789ab
DEVISE_PEPPER=89abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789ab
SECRET_KEY_BASE=$(bundle exec rails secret)
DATABASE_URL=postgres://rails:password@localhost:5432/may_is_bike_month_development
PARALLEL_TEST_FIRST_IS_1=true
```

### Database Setup
```bash
# Create and migrate development database - takes ~3 seconds
# Requires PostgreSQL running on localhost:5432
PGPASSWORD=password createdb -h localhost -p 5432 -U rails may_is_bike_month_development
bundle exec rails db:migrate

# Alternative: Use bin/setup for automated setup - takes ~4 seconds
bin/setup
```

### Build Assets
```bash
# Precompile assets for production testing - takes ~5 seconds. NEVER CANCEL.
bundle exec rails assets:precompile

# Remove precompiled assets for development (enables dynamic compilation)
rm -f public/assets/.manifest.json
```

## Development Workflow

### Start Development Server
```bash
# Start all services (Rails, Sidekiq, Tailwind) - takes ~6 seconds to start. NEVER CANCEL.
bundle exec foreman start -f Procfile.dev
```

This starts:
- **Web server**: Rails/Puma on http://localhost:3010
- **Background worker**: Sidekiq for job processing
- **CSS compilation**: Tailwind CSS with file watching

**Alternative: Individual services**
```bash
# Just Rails server
bundle exec rails server -p 3010

# Just Sidekiq worker (requires Redis)
bundle exec sidekiq

# Just Tailwind CSS building
bin/rails tailwindcss:watch
```

### Redis Requirement
Sidekiq requires Redis. If not available via Docker:
```bash
# Install and start Redis
sudo apt-get install redis-server
redis-server --daemonize yes
```

## Testing

### Unit Tests
```bash
# Run model tests only - takes ~3 seconds. NEVER CANCEL.
bundle exec rspec spec/models/

# Run all tests with turbo_tests (parallel) - takes ~5 minutes. NEVER CANCEL. Set timeout to 10+ minutes.
bundle exec turbo_tests

# Run specific test files
bundle exec turbo_tests spec/models/competition_spec.rb
```

### Test Environment Notes
- Some integration tests fail due to missing CSS assets - this is expected in development
- Model and service tests should pass consistently
- Use `bundle exec rspec` for standard (non-parallel) test execution if turbo_tests has issues

## Code Quality and Linting

### Linting
```bash
# Auto-fix Ruby and HTML formatting - takes ~5 seconds. NEVER CANCEL.
bin/lint

# Test-only mode (used in CI)
LINT_TEST=true bin/lint

# Individual linting commands
bundle exec standardrb --fix  # Ruby linting
yarn lint                    # JavaScript linting (via standard)
```

## Validation Scenarios

After making changes, ALWAYS test these scenarios to ensure the application works:

### Basic Application Functionality
1. **Start the server**: `bundle exec foreman start -f Procfile.dev`
2. **Visit homepage**: Navigate to http://localhost:3010
3. **Verify display**: Should show "MIBM 2024" leaderboard with competition data
4. **Check sign-in**: "Sign in" button should be visible in top navigation

### Database and Models
```bash
# Test database connection and basic models
echo "puts Competition.count; puts User.count; exit" | bundle exec rails console
```

### Background Jobs
```bash
# Verify Sidekiq is working (should show stats)
bundle exec rails console -e "puts Sidekiq::Stats.new.processed; exit"
```

## Important Directories and Files

### Application Structure
- **`app/models/`**: Core business logic (User, Competition, CompetitionUser, etc.)
- **`app/controllers/`**: HTTP request handling
- **`app/components/`**: ViewComponent-based UI components
- **`app/views/`**: ERB templates
- **`app/services/`**: Business logic services
- **`app/jobs/`**: Background job definitions

### Configuration
- **`config/database.yml`**: Database configuration
- **`config/routes.rb`**: URL routing
- **`Procfile.dev`**: Development services configuration
- **`.env.template`**: Environment variables template

### Testing
- **`spec/models/`**: Model unit tests
- **`spec/requests/`**: Integration tests
- **`spec/components/`**: Component tests
- **`spec/factories/`**: Test data factories

### Build and Deployment
- **`.github/workflows/`**: CI/CD pipeline configuration
- **`bin/`**: Executable scripts (dev, setup, lint, etc.)

## Common Troubleshooting

### Database Issues
- **"database does not exist"**: Run `PGPASSWORD=password createdb -h localhost -p 5432 -U rails may_is_bike_month_development`
- **Connection errors**: Ensure PostgreSQL is running on localhost:5432

### Asset Issues
- **"tailwind.css not found"**: Remove precompiled assets with `rm -f public/assets/.manifest.json`
- **CSS not updating**: Restart Tailwind watcher or run `bin/rails tailwindcss:build`

### Secret Key Issues
- **"Missing secret_key_base"**: Add `SECRET_KEY_BASE=$(bundle exec rails secret)` to `.env`

### Redis/Sidekiq Issues
- **Sidekiq connection errors**: Ensure Redis is running with `redis-cli ping`

## Performance Expectations

**NEVER CANCEL these operations - they complete within expected timeframes:**

- **Bundle install**: 45 seconds (fresh), 1 second (cached)
- **Yarn install**: 1-2 seconds  
- **Database migration**: 3-5 seconds
- **Asset precompilation**: 5 seconds
- **Development server startup**: 6 seconds
- **Model test suite**: 3 seconds
- **Full test suite**: 5 minutes (set timeout to 10+ minutes)
- **Linting**: 5 seconds

## CI/CD Integration

The application includes GitHub Actions workflows:
- **`ruby.yml`**: Main CI pipeline (build, test, lint)
- **`copilot-setup-steps.yml`**: Validation of these setup instructions

Always run `bin/lint` before committing to ensure CI passes.

## Strava Integration

The application integrates with Strava API:
- User authentication via OAuth
- Activity data synchronization
- Requires valid `STRAVA_CLIENT_ID` and `STRAVA_SECRET` for full functionality
- Background jobs (`UpdateCompetitionUserJob`) pull activity data

## Competition Management

Key workflow for running competitions:
```ruby
# Create new competition
competition = Competition.create(start_date: "2025-05-01", display_name: "2025")
competition.create_competition_users

# Manual controls available for competition scoring and activity inclusion
```