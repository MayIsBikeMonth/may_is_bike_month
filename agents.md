# May is Bike Month

This is a Rails app to track the score and generate the leaderboard for the May is Bike Month group.

# Development

Start the dev server with `bin/dev`

This will start a dev server at [localhost:3010](http://localhost:3010)

## Code style

Ruby is formatted with the standard gem. Run `bin/lint` to automatically format the code.

### Code guidelines:

- Code in a functional way. Avoid mutation (side effects) when you can.
- Don't mutate arguments
- Don't monkeypatch
- make methods private if possible
- Omit named arguments' values from hashes (ie prefer `{x:, y:}` instead of `{x: x, y: y}`)
- Prefer less code, by character count (excluding whitespace and comments). Use `bin/char_count {FILE OR FOLDER}` to get the non-whitespace character count
- prefer un-abbreviated variable names

## Testing

This project uses Rspec for tests. All business logic should be tested.

- Tests should either: help make the code correct now or prevent bugs in the future. Don't add tests that don't do one of those things.
- Use request specs, not controller specs. Everything making the same request should be in a single test
- Avoid testing private methods
- Avoid mocking objects
  - If making external requests, use VCR. Don't manually write VCR cassettes, record them by running the tests.
- Use `context` and `let` to isolate what varies between examples.
  - Each `it` block should live in a `context` that names the condition, with `let` overrides for only what differs in that case. Avoid repeating setup across sibling `it` blocks.

**Good:**
```ruby
describe "display_name" do
  let(:user) { User.new(email: "test@example.com", name:) }
  let(:name) { nil }

  it "returns email prefix when name is blank" do
    expect(user.display_name).to eq "test"
  end

  context "when name is present" do
    let(:name) { "Test User" }

    it "returns name" do
      expect(user.display_name).to eq "Test User"
    end
  end
end
```

**Bad:**
```ruby
it "returns display_name" do
  user = FactoryBot.create(:user, email: "test@example.com", name: "Test User")
  expect(user.display_name).to eq "Test User"
end
it "returns email prefix when name is blank" do
  user = FactoryBot.create(:user, email: "test@example.com")
  allow(user).to receive(:name) { nil }
  expect(user.display_name).to eq "test"
end
```

### Running Tests

Run tests with turbo_tests:

```bash
bundle exec turbo_tests
# Or, to run just specific tests
bundle exec turbo_tests {FILE OR FOLDER}
```

## Frontend Development

This project uses Stimulus.js for JavaScript interactivity and Tailwind CSS for styling. There are scss styles and coffeescript files, but they are deprecated.

The `bin/dev` command handles building and updating tailwind and JS.

- basic links should use the `twlink` class

This project also uses the ViewComponent gem to render components.

- Prefer view components to partials
- Generate a new view component with `rails generate component ComponentName argument1 argument2`
- View components must initialize with keyword arguments
- In view components, prefer instance variables to attr_accessor
- In ViewComponent templates, use `helpers.` prefix for view helpers (e.g. `helpers.time_ago_in_words`).
  - You don't need to prefix paths (e.g. do `new_bike_path` NOT `helpers.new_bike_path`)
- Always use `UI::Time::Component` to display time

# Initial setup

```bash
bundle install # install ruby dependencies
bundle exec rails db:create db:migrate # create the databases
cp .env.example .env
```
