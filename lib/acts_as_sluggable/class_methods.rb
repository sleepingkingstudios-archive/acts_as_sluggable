# lib/acts_as_sluggable/class_methods.rb

module SleepingKingStudios
  module ActsAsSluggable
    module ClassMethods
      
      # Configuration options:
      # - allow_lock: If enabled, can set the slug value manually and have that
      #   value preserved on save (otherwise, the value is just overriden by
      #   the callback). Requires an additional column to indicate the value is
      #   locked and not to be overriden - the default is :#{cache_column}_lock
      #   but can be overriden with the lock_column option (see below).
      # - callback: Procedure used to convert the source attribute to the slug
      #   value. Defaults to the built-in procedure. Ignored if the
      #   :callback_method parameter is set.
      # - callback_method: Overrides callback behaviour to call the specified
      #   method instead of the stored procedure to cache the slug value.
      # - cache_column: Used to set the name of the column where the slug value
      #   is cached. Defaults to :slug.
      # - lock_column: Used to set the name of the column indicating whether
      #   the current slug value is manually set and should not be overriden by
      #   the callback. Defaults to :#{cache_column}_lock. Ignored unless the
      #   allow_lock option is set (see above).
      # - separator: String used to separate words in the slug. Defaults to a
      #   single hyphen '-'.
      # - validates: Convenience method for giving validation methods to the
      #   slug value. Expects a Hash, passed directly to validates
      #   :#{cache_column}. Defaults to nil.
      def acts_as_sluggable(source_attr, options = {})
        # Set up configuration defaults.
        configuration = {
          allow_lock:      false,
          callback:        nil,
          callback_method: nil,
          cache_column:    :slug,
          lock_column:     nil,
          separator:       '-',
          validates:       nil
        } # end Hash
        configuration.update(options) if options.is_a? Hash
        configuration[:lock_column] ||= :"#{configuration[:cache_column]}_lock"
        configuration[:source_attr] = source_attr
        
        # Set up default callback if none is specified.
        unless configuration[:callback] && configuration[:callback].respond_to?(:call)
          configuration[:callback] = Proc.new { |source|
            source.to_s.underscore.gsub(/['"]/,"").parameterize('-').gsub(/[\s_-]+/, configuration[:separator])
          } # end Proc callback
        end # if-else
        
        # Apply validations (if any)
        if configuration[:validates]
          validates :"#{configuration[:cache_column]}", configuration[:validates]
        end # if
        
        # Guard against slug= allowing an incorrect value until the record is saved.
        if configuration[:allow_lock]
          define_method :"#{configuration[:cache_column]}=" do |value, force = false|
            self.send(:"#{configuration[:lock_column]}=", true) unless force
            super(value)
          end # define_method
        else
          define_method :"#{configuration[:cache_column]}=" do |value, force = false|
            force ? super(value) : raise(NoMethodError.new("undefined method `#{configuration[:cache_column]}=' for #{self}:#{self.class}"))
          end # define_method
        end # if-else
        
        before_validation do |sluggable|
          break if configuration[:allow_lock] && sluggable.send(configuration[:lock_column])
          if configuration[:callback_method]
            if self.method(configuration[:callback_method]).arity == 0
              sluggable.send :"#{configuration[:cache_column]}=",
                sluggable.send(configuration[:callback_method]), true
            else
              sluggable.send :"#{configuration[:cache_column]}=",
                sluggable.send(configuration[:callback_method], sluggable.send(configuration[:source_attr])), true
            end # if-else
          else
            sluggable.send :"#{configuration[:cache_column]}=",
              configuration[:callback].call(sluggable.send configuration[:source_attr]), true
          end # if-else
        end # before_save
      end # method acts_as_sluggable
    end # module ClassMethods
  end # module ActsAsSluggable
end # module SleepingKingStudios
