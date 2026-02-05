# frozen_string_literal: true

require_relative "lib/wide-events/version"

Gem::Specification.new do |spec|
  spec.name          = "wide-events"
  spec.version       = WideEvents::VERSION
  spec.authors       = ["Chakravarthi Dinavahi"]
  spec.email         = ["chakravarthi.dinavahi@gmail.com"]

  spec.summary       = "Wide events logging for Rails - comprehensive, contextual, and queryable"
  spec.description   = "Implements wide events pattern for Rails applications. Capture all context in a single event per request with tail sampling for cost control."
  spec.homepage      = "https://github.com/yourusername/wide-events"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end
