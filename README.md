# May is Bike Month

This is a Rails app to track the score and generate the leaderboard for the May is Bike Month group ([MayIsBikeMonth.org](https://mayisbikemonth.org/)).

### Dependencies

_We recommend [asdf-vm](https://asdf-vm.com/#/) for managing versions of Ruby and Node. Check the [.tool-versions](.tool-versions) file to see the versions of the following dependencies that Convus uses._

- [Ruby](http://www.ruby-lang.org/en/)
- [Node](https://nodejs.org/en/) & [yarn](https://yarnpkg.com/en/)
- PostgreSQL
- [Redis](http://redis.io/)

## Local working

You will need the `STRAVA_CLIENT_ID`, `STRAVA_SECRET` for your [Strava app](https://www.strava.com/settings/api)

Run these commands in the terminal, from the directory the project is in.

```bash
# Copy the .env.example in to be your .env - and fill in your strava secrets
cp .env.example .env
# Install dependencies, create and migrate the databases
bin/setup
# Start the dev server
bin/dev
```

View the dev server at [localhost:3010](http://localhost:3010)


Some development options:

| Toggle in development | command                      | default  |
| ---------             | -------                      | -------  |
| Caching               | `bundle exec rails dev:cache`| disabled |
| logging with lograge  | `bin/rake dev:lograge`       | enabled  |


### Testing

Run the tests with `bundle exec turbo_tests`


### Running a Competition

Create a new competition with:

```ruby
competition = Competition.create(start_date: "2025-05-01", display_name: "2025")
competition.create_competition_users
```

**NOTE** `competition_user`s are `included_in_competition: false` by default - you have to manually turn each one to true to be included

Some manual controls:

- Manually set the dates a `CompetitionActivity` is counted with `override_activity_dates_strings`
  - If set to `competition_activity.override_activity_dates_strings = []`, it makes the activity `included_in_competition: false`

- Manually set `CompetitionUser` permitted activity types with `included_activity_types` (a JSON array). This enables giving a single user permission for virtual rides (e.g. if they're injured)

## Deployment

Deploys to a DigitalOcean droplet with [Kamal](https://kamal-deploy.org/), using GHCR for container images and 1Password for secrets.

Requires [GitHub CLI](https://cli.github.com/) (`gh`), [1Password CLI](https://developer.1password.com/docs/cli/) (`op`), and [Docker](https://docs.docker.com/get-docker/).

```bash
bin/kamal deploy
```

CI also deploys from `main` via `.github/workflows/ruby.yml` — secrets there are pulled from repo GitHub Actions secrets rather than 1Password.

### Accessing the running app

From the project root:

```bash
bin/kamal shell    # bash in the web container
bin/kamal console  # rails console
bin/kamal dbc      # rails dbconsole
bin/kamal logs     # tail web logs
bin/kamal app logs -r worker -f   # tail sidekiq logs
```

For host-level access (Docker, disk, systemd), SSH directly to the droplet (IP in `config/deploy.yml`):

```bash
ssh root@<server_ip>
```

### Adding a new secret ENV var

Secrets need to be added in six places. Using `EXAMPLE_TOKEN` as the var name:

1. 1Password — add `EXAMPLE_TOKEN` to the `Kamal/MayIsBikeMonth` item in the `bike-index` account.
2. GitHub Actions — add `EXAMPLE_TOKEN` as a repo secret (Settings → Secrets and variables → Actions) so CI deploys can inject it.
3. `config/deploy.yml` — add to the `env.secret` list.
4. `.kamal/secrets` — add to the `kamal secrets fetch` args and add a matching `extract` line.
5. `.kamal/secrets-ci` — add a `EXAMPLE_TOKEN=$EXAMPLE_TOKEN` passthrough line.
6. `.github/workflows/ruby.yml` — add `EXAMPLE_TOKEN: ${{ secrets.EXAMPLE_TOKEN }}` to the deploy step env block.

### Initial production setup

One-time steps after the droplet and secrets are in place:

```bash
bin/kamal setup                    # first deploy (provisions accessories, etc.)
```

Strava webhooks must be registered once per environment. In a production rails console (`bin/kamal console`):

```ruby
StravaIntegration.create_webhook_subscription
# Check existing subscriptions:
StravaIntegration.view_webhook_subscriptions
# To remove one:
StravaIntegration.delete_webhook_subscription(subscription_id)
```

Strava will POST activity updates to `/webhooks/strava`, authenticated against `STRAVA_WEBHOOK_VERIFY_TOKEN`. Only one subscription can exist per Strava app — if you rotate `STRAVA_WEBHOOK_VERIFY_TOKEN`, delete and recreate the subscription.
