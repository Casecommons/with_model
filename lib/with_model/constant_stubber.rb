module WithModel
  class ConstantStubber
    def initialize const_name
      @const_name = const_name.to_sym
      @original_value = nil
    end

    def stub_const value
      if Object.const_defined?(@const_name)
        @original_value = Object.const_get(@const_name)
        Object.send :remove_const, @const_name
      end

      Object.const_set @const_name, value
    end

    def unstub_const
      Object.send :remove_const, @const_name
      Object.const_set @const_name, @original_value if @original_value
      @original_value = nil
    end
  end
  private_constant :ConstantStubber
end
