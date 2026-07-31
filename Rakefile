require "bridgetown"

Bridgetown.load_tasks

# Ruby unit/integration test suite (see test/). Namespaced under `test:` so it
# sits alongside the Bridgetown-provided `test` build task above without
# clobbering it. Run with `bundle exec rake test:ruby`.
require "rake/testtask"

namespace :test do
  desc "Run the Ruby test suite (test/**/*_test.rb)"
  Rake::TestTask.new(:ruby) do |t|
    t.libs << "test" << "lib"
    t.test_files = FileList["test/**/*_test.rb"]
    t.warning = false
    t.verbose = false
  end
end

# Run rake without specifying any command to execute a deploy build by default.
task default: :deploy

#
# Standard set of tasks, which you can customize if you wish:
#
desc "Build the Bridgetown site for deployment"
task deploy: [:clean, "frontend:build"] do
  Bridgetown::Commands::Build.start
end

desc "Build the site in a test environment"
task :test do
  ENV["BRIDGETOWN_ENV"] = "test"
  Bridgetown::Commands::Build.start
end

desc "Runs the clean command"
task :clean do
  Bridgetown::Commands::Clean.start
end

namespace :frontend do
  desc "Build the frontend with esbuild for deployment"
  task :build do
    sh "npm run esbuild"
  end

  desc "Watch the frontend with esbuild during development"
  task :dev do
    sh "npm run esbuild-dev"
  rescue Interrupt
  end
end

#
# Add your own Rake tasks here! You can use `environment` as a prerequisite
# in order to write automations or other commands requiring a loaded site.
#
# task :my_task => :environment do
#   puts site.root_dir
#   automation do
#     say_status :rake, "I'm a Rake tast =) #{site.config.url}"
#   end
# end
