require "active_support/descendants_tracker"

module WithModel
  # Based on https://github.com/rails/rails/blob/491afff27e2dd3d5f301b478b9a43d3c31709af8/activesupport/lib/active_support/descendants_tracker.rb
  module DescendantsTracker
    if RUBY_ENGINE == "ruby"
      # On MRI `ObjectSpace::WeakMap` keys are weak references.
      # So we can simply use WeakMap as a `Set`.
      class WeakSet < ObjectSpace::WeakMap # :nodoc:
        alias_method :to_a, :keys

        def <<(object)
          self[object] = true
        end
      end
    else
      # On TruffleRuby `ObjectSpace::WeakMap` keys are strong references.
      # So we use `object_id` as a key and the actual object as a value.
      #
      # JRuby for now doesn't have Class#descendant, but when it will, it will likely
      # have the same WeakMap semantic than Truffle so we future proof this as much as possible.
      class WeakSet # :nodoc:
        def initialize
          @map = ObjectSpace::WeakMap.new
        end

        def [](object)
          @map.key?(object.object_id)
        end
        alias_method :include?, :[]

        def []=(object, _present)
          @map[object.object_id] = object
        end

        def to_a
          @map.values
        end

        def <<(object)
          self[object] = true
        end
      end
    end
    @excluded_descendants = WeakSet.new

    class << self
      def clear(classes) # :nodoc:
        classes.each do |klass|
          @excluded_descendants << klass
          klass.descendants.each do |descendant|
            @excluded_descendants << descendant
          end
        end
      end

      def reject!(classes) # :nodoc:
        if @excluded_descendants
          classes.reject! { |d| @excluded_descendants.include?(d) }
        end
        classes
      end
    end

    module ReloadedClassesFiltering # :nodoc:
      def subclasses
        WithModel::DescendantsTracker.reject!(super)
      end

      def descendants
        WithModel::DescendantsTracker.reject!(super)
      end
    end
  end
end

class Class
  prepend WithModel::DescendantsTracker::ReloadedClassesFiltering
end

module ActiveSupport
  module DescendantsTracker
    class << self
      attr_reader :clear_disabled
    end
  end
end
