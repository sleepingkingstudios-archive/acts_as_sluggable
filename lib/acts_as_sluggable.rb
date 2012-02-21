require 'active_record'
require 'acts_as_sluggable/class_methods'

ActiveRecord::Base.send :extend, SleepingKingStudios::ActsAsSluggable::ClassMethods
