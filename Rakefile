$:.unshift("/Library/RubyMotion/lib")

require 'motion/project'
require "bundler/gem_tasks"
require "bundler/setup"
Bundler.require :default

require 'webstub'

$:.unshift("./lib/")
require './lib/elevate'

Motion::Project::App.setup do |app|
  app.name = "elevate"

  if ENV["DEFAULT_PROVISIONING_PROFILE"]
    app.provisioning_profile = ENV["DEFAULT_PROVISIONING_PROFILE"]
  end
end

