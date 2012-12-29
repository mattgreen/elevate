$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'

require 'bundler'
Bundler.setup
Bundler.require

Motion::Project::App.setup do |app|
  base_dir = File.dirname(__FILE__)
  gemspec = Dir.glob(File.join(base_dir, "*.gemspec")).first
  gem_name = File.basename(gemspec).gsub("\.gemspec", "")

  app.files = Dir.glob(File.join(base_dir, "app/*.rb"))
  app.files += Dir.glob(File.join(base_dir, "lib/#{gem_name}/**/*.rb"))

  app.name = "#{gem_name}"
end

namespace :spec do
  desc "Auto-run specs"
  task :guard do
    sh "bundle exec guard"
  end
end
