# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/utils", under: "utils"
pin "@honeybadger-io/js", to: "https://cdn.jsdelivr.net/npm/@honeybadger-io/js@6.12.3/dist/browser/honeybadger.min.js"
pin "luxon", to: "https://cdn.jsdelivr.net/npm/luxon@3.7.1/build/es6/luxon.js"
pin "@bikeindex/time-localizer", to: "https://cdn.jsdelivr.net/npm/@bikeindex/time-localizer@0.2.1/dist/index.js"
pin "@floating-ui/dom", to: "https://cdn.jsdelivr.net/npm/@floating-ui/dom@1.7.3/+esm"
# preload: false so a component rendered on a handful of pages doesn't fetch 10KB
# on every page -- the controller import()s them for the same reason.
pin "highlight.js/lib/core", to: "highlight.js--core.js", preload: false
pin "highlight.js/lib/languages/json", to: "highlight.js--json.js", preload: false
pin "@rails/activestorage", to: "activestorage.esm.js", preload: false
pin "chartkick", to: "chartkick.js"
pin "Chart.bundle", to: "Chart.bundle.js"

# Our components
pin_all_from "app/components", under: "components", to: ""
