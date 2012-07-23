class DbcObject
  attr_reader :dbc_name, :dbc_class, :dbc_methods

  def initialize(dbc_name, dbc_class, dbc_instance_variables)
    @dbc_name = dbc_name
    @dbc_class = dbc_class
    @dbc_methods = []
    initialize_dbc_instance_variables(dbc_instance_variables)
    define_singleton_attribute_accessors(dbc_instance_variables.keys)
  end

  def satisfy?(&condition)
    instance_eval(&condition)
  end

  def apply(&postcondition)
    instance_eval(&postcondition)
  end

  def add_dbc_method(method)
    @dbc_methods << method
    method.receiver_name = @dbc_name
  end

  private

  def initialize_dbc_instance_variables(dbc_instance_variables)
    dbc_instance_variables.each do |name, value|
      instance_variable_set(name, value)
    end
  end

  def define_singleton_attribute_accessors(dbc_instance_variables_names)
    dbc_instance_variables_names.each do |name|
      eigenclass.class_eval do
        attr_accessor name.to_s.delete('@').to_sym
      end
    end
  end

  def eigenclass
    class << self
      self
    end
  end
end
