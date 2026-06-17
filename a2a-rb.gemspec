require_relative "lib/a2a/version"

Gem::Specification.new do |spec|
  spec.name    = "a2a-rb"
  spec.version = A2A::VERSION
  spec.authors = ["r.figueiredo@dermanostic.com"]
  spec.email   = ["r.figueiredo@dermanostic.com"]

  spec.summary     = "Ruby implementation of the A2A protocol"
  spec.description = "Ruby implementation of the A2A protocol"
  spec.homepage    = "https://github.com/your-org/a2a-rb"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob("{lib}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  spec.files += %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "pry",   "~> 0.14"
  spec.add_development_dependency "rake",  "~> 13.0"
end
