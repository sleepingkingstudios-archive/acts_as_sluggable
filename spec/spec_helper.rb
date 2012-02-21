# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require "rails/test_help"

Rails.backtrace_cleaner.remove_silencers!

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Monkey patch RSpec::ExampleGroup
class RSpec::Core::ExampleGroup
  class << self
    def context(*args, &block)
      describe((args.first.nil? ? args.shift : "\n#{"  " * self.ancestors.count}(#{args.shift})"), *args, &block)
    end # define_method
  end # class << self
end # class ExampleGroup
