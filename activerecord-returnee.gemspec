
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record/returnee/version"

Gem::Specification.new do |spec|
  spec.name          = "activerecord-returnee"
  spec.version       = ActiveRecord::Returnee::VERSION
  spec.authors       = ["yalab"]
  spec.email         = ["rudeboyjet@gmail.com"]

  spec.summary       = %q{This gem provides migration or model generate from Database schema.}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/yalab/activerecord-returnee"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "pg"
  spec.add_dependency "activerecord", ">= 5.0"
  spec.add_dependency "railties", ">= 5.0"
end
