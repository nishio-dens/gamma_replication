# frozen_string_literal: true

require_relative "lib/gamma_replication/version"

Gem::Specification.new do |spec|
  spec.name = "gamma_replication"
  spec.version = GammaReplication::VERSION
  spec.authors = ["Shinsuke Nishio"]
  spec.email = ["nishio@densan-labs.net"]

  spec.summary = "MySQL replication tool with data masking capability"
  spec.description = "A tool to replicate MySQL data with the ability to mask sensitive information using Maxwell's Daemon"
  spec.homepage = "https://github.com/nishio-dens/gamma_replication"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[
    lib/**/*.rb
    bin/*
    *.gemspec
    README.md
    LICENSE.txt
  ])
  spec.bindir = "exe"
  spec.executables = ["gamma_replication"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "mysql2", "~> 0.5.5"
  spec.add_dependency "thor", "~> 1.3"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
