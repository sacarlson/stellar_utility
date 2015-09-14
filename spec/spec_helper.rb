require 'bundler/setup'
Bundler.setup

require 'simplecov'
SimpleCov.start

require 'pry'
require 'stellar-base'
require './lib/stellar_utility/stellar_utility.rb'

SPEC_ROOT = File.dirname(__FILE__)

Dir["#{SPEC_ROOT}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|

end
