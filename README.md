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
# Copy the .env.template in to be your .env - and fill in your strava secrets
cp .env.template .env
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

### Prerequisites

- [GitHub CLI](https://cli.github.com/) (`gh`) -- logged in with `write:packages` scope
- [1Password CLI](https://developer.1password.com/docs/cli/) (`op`) -- logged in
- [DigitalOcean CLI](https://docs.digitalocean.com/reference/doctl/) (`doctl`) -- logged in
- [Docker](https://docs.docker.com/get-docker/) with the [buildx plugin](https://github.com/docker/buildx)

### Create a droplet

```bash
# Add your SSH key to DigitalOcean (if not already added)
doctl compute ssh-key import my-key --public-key-file ~/.ssh/id_ed25519.pub

# Get your SSH key ID
doctl compute ssh-key list

# Create a droplet (s-1vcpu-2gb = $12/mo)
doctl compute droplet create may-is-bike-month \
  --region sfo3 \
  --size s-1vcpu-2gb \
  --image ubuntu-24-04-x64 \
  --ssh-keys YOUR_SSH_KEY_ID \
  --wait
```

Note the droplet's IP address from the output.

### Point your domain

Add a DNS A record pointing your domain to the droplet IP. If using Cloudflare, set it to **DNS only** (gray cloud, not proxied) so Let's Encrypt can issue a certificate.

### Configure deployment

```bash
bin/setup_deploy
```

This will prompt for your deploy host, server IP, and GitHub username, then:
- Update `config/deploy.yml` with your server and registry details
- Update `.kamal/secrets` with your 1Password account
- Update `config/environments/production.rb` with your mailer host
- Create a 1Password item in the `Kamal` vault with `RAILS_MASTER_KEY`, `HONEYBADGER_API_KEY`, and `POSTGRESQL_PASSWORD`

After running `bin/setup_deploy`, update the `HONEYBADGER_API_KEY` value in 1Password, then deploy:

```bash
bin/kamal setup
```

This first deploy will install Docker on the server, push the image to GHCR, boot a PostgreSQL container, provision a Let's Encrypt SSL certificate, and start the app.

### Subsequent deploys

```bash
bin/kamal deploy
```

### Useful aliases

```bash
bin/kamal console   # Rails console on the server
bin/kamal shell     # Bash shell on the server
bin/kamal logs      # Tail production logs
bin/kamal dbc       # Database console
```
