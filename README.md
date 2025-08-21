# May is Bike Month

This is a Rails app to track the score and generate the leaderboard for the May is Bike Month group ([MayIsBikeMonth.org](https://mayisbikemonth.org/)).

### Dependencies

_We recommend [asdf-vm](https://asdf-vm.com/#/) for managing versions of Ruby and Node. Check the [.tool-versions](.tool-versions) file to see the versions of the following dependencies that Convus uses._

- [Ruby](http://www.ruby-lang.org/en/)
- [Node](https://nodejs.org/en/) & [yarn](https://yarnpkg.com/en/)
- PostgreSQL
- [Redis](http://redis.io/)

## local working

You will need the `STRAVA_CLIENT_ID`, `STRAVA_SECRET` for your [Strava app](https://www.strava.com/settings/api)

Run these commands in the terminal, from the directory the project is in.

```bash
# Install the ruby gems with
bundle install
# Install the node packages with
yarn install
# Create and migrate the databases
bundle exec rake db:create db:migrate db:test:prepare
# Copy the .env.template in to be your .env - and fill in your strava secrets
cp .env.template .env
# start the dev server
./bin/dev
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
