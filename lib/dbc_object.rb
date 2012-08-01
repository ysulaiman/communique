class DbcObject
  attr_reader :dbc_name, :dbc_class, :dbc_methods

  def initialize(dbc_name, dbc_class, dbc_instance_variables)
    @dbc_name = dbc_name
    @dbc_class = dbc_class
    @dbc_methods = []
    @dbc_instance_variables = dbc_instance_variables
    initialize_dbc_instance_variables
    define_singleton_attribute_accessors(@dbc_instance_variables.keys)
  end

  def satisfy?(&condition)
    instance_eval(&condition)
  end

  def apply(&postcondition)
    instance_eval(&postcondition)
  end

  def add_dbc_methods(*methods)
    @dbc_methods.concat(methods)
    methods.each { |m| m.receiver_name = @dbc_name }
  end

  def reset_instance_variables
    initialize_dbc_instance_variables
    reset_instance_variables_that_are_dbc_objects
  end

  private

  def initialize_dbc_instance_variables
    @dbc_instance_variables.each do |name, value|
      instance_variable_set(name, value)
    end
  end

  def reset_instance_variables_that_are_dbc_objects
    dbc_objects = @dbc_instance_variables.select { |k, v| v.is_a? DbcObject }
    dbc_objects.each_value { |dbc_object| dbc_object.reset_instance_variables }
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
