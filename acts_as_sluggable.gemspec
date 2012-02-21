$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "acts_as_sluggable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "acts_as_sluggable"
  s.version     = SleepingKingStudios::ActsAsSluggable::VERSION
  s.authors     = ["Rob Smith"]
  s.email       = ["merlin@sleepingkingstudios.com"]
  s.homepage    = "sleepingkingstudios.com"
  s.summary     = "Automatically updates short \"slug\" string field."
  s.description = "#{s.summary}"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.1"

  s.add_development_dependency "sqlite3"
end # Gem::Specification
