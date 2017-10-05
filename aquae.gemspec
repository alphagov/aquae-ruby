# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "aquae/version"

Gem::Specification.new do |spec|
  # Count the number of commits between us and the last release.
  # Use this to give the Gem package a unique build number.
  # Make sure we're in the right working-dir before doing this,
  # so the specification is accurate when loaded in other projects.
  *tag, count, hash, dirty = `git -C "#{File.dirname __FILE__}" describe --tags --dirty`.chomp.split('-')
  unless dirty == 'dirty'
    count, hash = hash, dirty
  end

  spec.name          = 'aquae'
  # Still use Aquae::VERSION as the base version, and then add
  # the number of commits since that release as a patch.
  # If we're in a dirty working dir, add the dev flag.
  spec.version       = "#{Aquae::VERSION}.#{count}#{dirty ? '.dev' : ''}"
  spec.authors       = ["Simon Worthington"]
  spec.email         = ["simon.worthington@digital.cabinet-office.gov.uk"]
  spec.license       = 'MIT'

  spec.summary       = %q{Implements a protocol for personal data exchange.}
  spec.description   = <<-HEREDOC
    This gem is a low-level library for interacting with an AQuAE (Attributes,
    Questions, Answers and Elibility) system. It provides the APIs for opening
    connections and sending messages between nodes, on top of which applications
    can be written.
    HEREDOC
  spec.homepage      = "https://www.github.com/alphagov/aquae-corundum"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  #if spec.respond_to?(:metadata)
  #  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  #else
  #  raise "RubyGems 2.0 or newer is required to protect against " \
  #    "public gem pushes."
  #end

  spec.files         = `git -C "#{File.dirname __FILE__}" ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "protobuf", "~> 3.7"
  spec.add_dependency "rgl", "~> 0.5.3"
  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit", "~> 3.2"
end
