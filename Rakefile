$:.unshift("/Library/RubyMotion/lib")

begin
  if ENV['osx']
    require 'motion/project/template/osx'
  else
    require 'motion/project/template/ios'
  end

rescue LoadError
  require 'motion/project'
end

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

