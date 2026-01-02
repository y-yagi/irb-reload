# frozen_string_literal: true

require_relative "lib/irb/reload/version"

Gem::Specification.new do |spec|
  spec.name = "irb-reload"
  spec.version = IRB::Reload::VERSION
  spec.authors = ["Yuji Yaginuma"]
  spec.email = ["yuuji.yaginuma@gmail.com"]

  spec.summary = "Auto-reload changed Ruby files inside an IRB session."
  spec.homepage = "https://github.com/y-yagi/irb-reload"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "irb", "~> 1.13"
  spec.add_dependency "listen", "~> 3.8"
end
