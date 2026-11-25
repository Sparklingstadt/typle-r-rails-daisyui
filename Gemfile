source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.4"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record in development and test
gem "sqlite3", ">= 2.1"
# PostgreSQL in production (Render)
gem "pg", "~> 1.6"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

gem "csv"

# Sparklingstadt ID (OpenID Connect, configured by SID_ISSUER, SID_CLIENT_ID and SID_CLIENT_SECRET) and GitHub sign-in
# (configured by GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET)
gem "omniauth"
gem "omniauth_openid_connect"
gem "omniauth-github"
gem "omniauth-rails_csrf_protection"
# omniauth-github's OAuth client; older versions leak the bearer token on a redirect (GHSA-fpw7-h52c-3w8x and later).
gem "oauth2", ">= 2.0.22"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end

group :test do
  # The Sparklingstadt ID server's discovery, keys and token endpoint, answered in the tests.
  gem "webmock"
  # Matchers for the component tests (test/components) and the system tests (test/system).
  gem "capybara"
  # The system tests' browser: headless Chrome driven over the DevTools protocol, with no driver to match.
  gem "cuprite"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

# Tailwind CSS v4 with daisyUI 5 (vendored in app/assets/tailwind), and lucide icons.
gem "tailwindcss-rails", "~> 4.0"
gem "lucide-rails"
gem "tailwind_merge"
# The UI's parts as components (app/components), with their own tests and previews.
gem "view_component"
