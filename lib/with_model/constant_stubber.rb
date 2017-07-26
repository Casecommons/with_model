module WithModel
  class ConstantStubber
    def initialize const_name, namespace
      @namespace = namespace
      @const_name = const_name.to_sym
      @original_value = nil
    end

    def stub_const value
      if @namespace.const_defined?(@const_name)
        @original_value = @namespace.const_get(@const_name)
        @namespace.send :remove_const, @const_name
      end

      @namespace.const_set @const_name, value
    end

    def unstub_const
      @namespace.send :remove_const, @const_name
      @namespace.const_set @const_name, @original_value if @original_value
      @original_value = nil
    end
  end
  private_constant :ConstantStubber
end
