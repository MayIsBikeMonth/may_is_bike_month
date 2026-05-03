# May is Bike Month

This is a Rails app to track the score and generate the leaderboard for the May is Bike Month group.

Be brief

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

Uses RSpec. All business logic should be tested. The `rspec-testing` skill covers project-specific style (`context`+`let`, request specs over controller specs, avoiding mocks).

## Frontend Development

Uses Stimulus.js for JavaScript and Tailwind CSS for styling. The `bin/dev` command handles Tailwind and JS builds.

The `frontend-conventions` skill covers the `twinput`/`twlabel`/`twlink` classes, the `number_display` helper, the `UI::Time::Component`, and ViewComponent rules.

## Pull requests

- When creating a PR, run the `/pr` workflow rather than calling `gh pr create` directly — `/pr` detects frontend diffs, captures desktop+mobile screenshots, and embeds them in the PR body.
- To attach a local image (screenshot, .png/.jpg, CleanShot capture) to an existing GitHub PR, the `gh` CLI **cannot upload images** — use the `github-upload-image-to-pr` skill, which drives a real browser to GitHub's user-attachments uploader.

# Initial setup

```bash
bundle install # install ruby dependencies
bundle exec rails db:create db:migrate # create the databases
cp .env.example .env
```
