# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'synapse-nginx'

Gem::Specification.new do |gem|
  gem.name          = "synapse-nginx"
  gem.version       = Synapse::Nginx::VERSION
  gem.authors       = ["Joseph Lynch"]
  gem.email         = ["jlynch@yelp.com"]
  gem.description   = "Nginx config_generator for Synapse"
  gem.summary       = %q{Dynamic NGINX configuration plugin for Synapse}
  gem.homepage      = "https://github.com/jolynch/synapse-nginx"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
end
