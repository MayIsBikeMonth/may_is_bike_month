# May is Bike Month

This is a Rails app to track the score and generate the leaderboard for the May is Bike Month group.

Copy the `.env.template` file to `.env` and fill in the values for your [Strava app](https://www.strava.com/settings/api)

### Dependencies

_We recommend [asdf-vm](https://asdf-vm.com/#/) for managing versions of Ruby and Node. Check the [.tool-versions](.tool-versions) file to see the versions of the following dependencies that Convus uses._

- [Ruby](http://www.ruby-lang.org/en/)

- [Rails](http://rubyonrails.org/)

- [Node](https://nodejs.org/en/) & [yarn](https://yarnpkg.com/en/)

- PostgreSQL

- [Redis](http://redis.io/)

## local working

Run these commands in the terminal, from the directory the project is in.

- Install the ruby gems with `bundle install`

- Install the node packages with `yarn install`

- Create and migrate the databases `bundle exec rake db:create db:migrate db:test:prepare`

- `./bin/dev` start the server.

- Go to [localhost:3010](http://localhost:3010)

| Toggle in development | command                      | default  |
| ---------             | -------                      | -------  |
| Caching               | `bundle exec rails dev:cache`| disabled |
| logging with lograge  | `bin/rake dev:lograge`       | enabled  |



This is a Rails re-write of the [phoenix/elixir May is Bike Month app](https://github.com/MayIsBikeMonth/may_is_bike_month-elixir)

---

Create a new competition with:

```ruby
competition = Competition.create(start_date: Date.parse("2025-05-01"), display_name: "2025")
competition.create_competition_users
```

Some manual controls:

- Manually set the dates a `CompetitionActivity` is counted with `override_activity_dates_string`
  - If set to `competition_activity.override_activity_dates_string = "none"`, it makes the activity `included_in_competition: false`

- Manually set `CompetitionUser` permitted activity types with `included_activity_types` (a JSON array). This enables giving a single user permission for virtual rides (e.g. if they're injured)
