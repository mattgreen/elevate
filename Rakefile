$:.unshift("/Library/RubyMotion/lib")
require 'motion/project'

require 'bundler'
Bundler.setup
Bundler.require

Motion::Project::App.setup do |app|
  gemspec = Dir.glob(File.join(File.dirname(__FILE__), "*.gemspec")).first
  gem_name = File.basename(gemspec).gsub("\.gemspec", "")

  app.development do
    app.files += Dir.glob(File.join(File.dirname(__FILE__), "lib/#{gem_name}/**/*.rb"))

    app.files << File.join(File.dirname(__FILE__), "lib/spec/spec_delegate.rb")
    app.delegate_class = "SpecDelegate"
  end

  app.name = "#{gem_name}"
end

namespace :spec do
  desc "Auto-run specs"
  task :guard do
    sh "bundle exec guard"
  end
end
