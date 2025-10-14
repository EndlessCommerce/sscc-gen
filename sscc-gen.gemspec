# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("lib", __dir__)
require "sscc_gen/version"

Gem::Specification.new do |spec|
  spec.name          = "sscc-gen"
  spec.version       = SsccGen::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["you@example.com"]

  spec.summary       = "Serial Shipping Container Code (SSCC) Generator"
  spec.description   = "Dependency-free Ruby gem to generate GS1 SSCC-18 identifiers with configurable serial providers."
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.2"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
