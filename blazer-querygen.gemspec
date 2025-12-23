# frozen_string_literal: true

require_relative "lib/blazer/querygen/version"

Gem::Specification.new do |spec|
  spec.name = "blazer-querygen"
  spec.version = Blazer::Querygen::VERSION
  spec.authors = ["mat_aki"]
  spec.email = ["mat_aki@sonicgarden.jp"]

  spec.summary = "AI-powered query generation for Blazer"
  spec.description = "Extend Blazer with OpenAI-powered SQL query generation from natural language prompts"
  spec.homepage = "https://github.com/mat_aki/blazer-querygen"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mat_aki/blazer-querygen"
  spec.metadata["changelog_uri"] = "https://github.com/mat_aki/blazer-querygen/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/ .rubocop.yml])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "blazer", ">= 2.0"
  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "ruby-openai", "~> 6.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
