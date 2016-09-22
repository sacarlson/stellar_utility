# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stellar_utility/version'

Gem::Specification.new do |spec|
  spec.name          = "stellar_utility"
  spec.version       = StellarUtility::VERSION
  spec.authors       = ["sacarlson"]
  spec.email         = ["sacarlson_2000@yahoo.com"]

  spec.summary       = %q{a small ruby utility lib for the new stellar-core that I used to learn with added examples}
  spec.description   = %q{cool stuf to play with}
  spec.homepage      = "https://github.com/sacarlson/stellar_utility"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "stellar-base"
  spec.add_dependency "faraday"
  spec.add_dependency "faraday_middleware"
  spec.add_dependency "json"
  spec.add_dependency "rest-client"
  spec.add_dependency "sqlite3"
  spec.add_dependency "pg"
  spec.add_dependency "rspec-kickstarter"
  spec.add_dependency "rspec"
  spec.add_dependency "rspec-core"
  spec.add_dependency 'simplecov'
  spec.add_dependency 'mysql'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
end
