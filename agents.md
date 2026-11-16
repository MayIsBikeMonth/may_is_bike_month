# May is Bike Month

This is a Rails app to track the score and generate the leaderboard for the May is Bike Month group.

Be brief

# Development

Start the dev server with `bin/dev`

This will start a dev server at [localhost:3010](http://localhost:3010)

## Code style

Ruby is formatted with the standard gem. Run `bin/lint` to automatically format the code.

**Pass it the files or directories you changed** — `bin/lint app/components/ui/table app/models/user.rb`. A bare `bin/lint` walks the whole repo; save it for a final check. **Never revert what the linter wrote** — if a too-broad run reformats other files, leave those fixes in.

### Code guidelines:

- Code in a functional way. Avoid mutation (side effects) when you can.
- Don't mutate arguments
- Don't monkeypatch
- make methods private if possible
- Omit named arguments' values from hashes (ie prefer `{x:, y:}` instead of `{x: x, y: y}`)
- Prefer less code, by character count (excluding whitespace and comments). Use `bin/char_count {FILE OR FOLDER}` to get the non-whitespace character count
- prefer un-abbreviated variable names
- Use full class/module names (`UI::Button::Component`, not a `Button::Component` lexical scope resolves). A class naming *itself* uses `self.class`
- **Prefer composition over inheritance and `include`.** Share behavior by calling an object that owns it; a module extracted only to be `include`d in two classes is usually one class with a parameter. Rails' own extension points (`ApplicationRecord`, `ActiveSupport::Concern` for controller filters) are fine
- **Service objects** (`app/services/`): a stateless service is a `module` with `extend Functionable` — inputs as args, no instance state, private methods via `conceal`. `StravaIntegration` is the pattern
- **Class methods go in a `class << self` block** when there are more than 5, or any should be private
- **An endless method takes a trailing `if`/`unless` on the *definition*, not the body** — `def centering = "mx-auto" if @alignment == :center` evaluates once in the class body, so the method is never defined. Give it a real body when the result is conditional

### Comments

- **Default to no comment.** A comment earns its place only by carrying *why* — a non-obvious constraint, a deliberate deviation, a gotcha.
- **Never narrate the code or the change** ("loop over users", "fixed X", "as requested").
- **Razor the wording** — keep the one non-obvious fact a reader needs at that line; cut mechanism the code shows and downstream consequences.
- **Re-earn the comment when you edit the code under it.**

## Testing

Uses RSpec. All business logic should be tested. The `rspec-testing` skill covers project-specific style (`context`+`let`, request specs over controller specs, avoiding mocks). A test that fails intermittently is the `fixing-flaky-failures` skill — coverage never gives way to make CI green.

**Verify with `bundle exec rspec` over the spec files covering what you changed**, not the whole suite. Say which specs you ran and why those.

**Never hand-edit a VCR cassette**, and never `git checkout` away one a spec run re-recorded. To clear stale contents, `rm` the file and re-run the spec.

## Frontend Development

Uses Stimulus.js for JavaScript and Tailwind CSS for styling. The `bin/dev` command handles Tailwind and JS builds.

Converting hand-written markup to existing `UI::*` components is the `use-existing-markup` skill. The `frontend-conventions` skill covers the `twinput`/`twlabel`/`twlink` classes, the `number_display` helper, the `UI::Time::Component`, and ViewComponent rules.

## Pull requests

- Bringing a branch up to date or resolving conflicts is the `merge-conflicts` skill — merge, never rebase.
- **Merging a PR is the human's, including when they ask you to do it in the moment.** Say the PR is ready and leave it.
- When creating a PR, run the `/pr` workflow rather than calling `gh pr create` directly — `/pr` detects frontend diffs, captures desktop+mobile screenshots, and posts them as a `## Screenshots` PR comment.
- To attach a local image (screenshot, .png/.jpg, CleanShot capture) to an existing GitHub PR, use the `github-pr-images` skill.

# Initial setup

```bash
bundle install # install ruby dependencies
bundle exec rails db:create db:migrate # create the databases
cp .env.example .env
```
