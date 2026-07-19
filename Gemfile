####
# Welcome to your project's Gemfile, used by Rubygems & Bundler.
#
# To install a plugin, run:
#
#   bundle add new-plugin-name
#
# and add a relevant init comment to your config/initializers.rb file.
#
# When you run Bridgetown commands, we recommend using a binstub like so:
#
#   bin/bridgetown start (or console, etc.)
#
# This will help ensure the proper Bridgetown version is running.
####

# Gems source:
source "https://rubygems.org"
# Or you can switch the above to an alternate community-led server:
# source "https://gem.coop"

# Git-based sources:
git_source(:github) { "https://github.com/#{it}.git" }
git_source(:codeberg) { "https://codeberg.org/#{it}.git" }

# If you need to upgrade/switch Bridgetown versions, change the line below
# and then run `bundle update bridgetown`
gem "bridgetown", "~> 2.2.2"

# Uncomment to add file-based dynamic routing to your project:
# gem "bridgetown-routes", "~> 2.2.2"

# Generates sitemap.xml with per-URL lastmod dates derived from git history.
gem "bridgetown-sitemap", "~> 3.0"

# The Rack-compliant web server
# (you can optionally limit this to the "development" group)

gem "falcon"

# Powers the Inspectors API (see plugins/builders/external_links.rb, which
# rewrites outbound <a> tags). Nokolexbor is the fast HTML-only parser; our
# resources are all HTML, so we don't need Nokogiri's broader XML support.
gem "nokolexbor", "~> 0.6"

group :development do
  # Ruby linter/formatter (RuboCop under the hood). Ships a ruby-lsp addon, so
  # editors auto-pick it up for formatting and diagnostics.
  gem "standard", "~> 1.0"
end

group :test do
  # Checks the built output/ for broken internal links, images, etc. Used in CI.
  gem "html-proofer", "~> 5.2"

  # Ruby's standard unit-testing framework. Drives the suite under test/ that
  # covers the plain-Ruby code (lib/slugs.rb) and the script/*.rb content
  # guards. Run with `bundle exec rake test:ruby`.
  gem "minitest", "~> 5.20"

  # `Rake::TestTask` for the `test:ruby` task (see the Rakefile).
  gem "rake", "~> 13.0"
end
