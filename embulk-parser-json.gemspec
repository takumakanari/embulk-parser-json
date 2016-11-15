# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "embulk-parser-json"
  spec.version       = "0.0.3"
  spec.authors       = ["Takuma kanari"]
  spec.email         = ["chemtrails.t@gmail.com"]
  spec.summary       = %q{Embulk parser plugin for json with jsonpath}
  spec.description   = %q{Json parser plugin is Embulk plugin to fetch entries in json format with jsonpath.}
  spec.homepage      = "https://github.com/takumakanari/embulk-parser-json"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "jsonpath", "~> 0.5"
  spec.add_development_dependency "bundler", "~> 1.0"
  spec.add_development_dependency "rake", "~> 10.0"
end
