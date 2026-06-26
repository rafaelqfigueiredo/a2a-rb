# frozen_string_literal: true

require_relative "lib/a2a/version"

Gem::Specification.new do |spec|
  spec.name    = "a2a-rb"
  spec.version = A2A::VERSION
  spec.authors = ["Rafael Figueiredo"]
  spec.email   = ["rafaelqfigueir@gmail.com"]

  spec.summary     = "Ruby implementation of the A2A protocol v1.0"
  spec.description = "Data model, serialisation, full client (JSON-RPC 2.0 + HTTP+JSON), " \
                     "streaming over SSE, push notifications, and server-side primitives for building A2A agents."
  spec.homepage    = "https://github.com/rafaelqfigueiredo/a2a-rb"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata["homepage_uri"]          = spec.homepage
  spec.metadata["source_code_uri"]       = spec.homepage
  spec.metadata["changelog_uri"]         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["allowed_push_host"]     = "https://rubygems.org"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("{lib}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
  spec.files += %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]
end
