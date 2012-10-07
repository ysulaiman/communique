class DbcObject
  attr_accessor :state
  attr_reader :dbc_name, :dbc_class, :dbc_methods, :dbc_instance_variables

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

  def ==(other)
    return true if other.equal?(self)
    return false unless other.instance_of?(self.class)

    other.dbc_name == @dbc_name && other.dbc_class == @dbc_class &&
      has_equal_dbc_instance_variables?(other) &&
      other.dbc_methods == @dbc_methods
  end

  def clone
    copy = DbcObject.new(@dbc_name.clone, @dbc_class, @dbc_instance_variables.clone)

    @dbc_instance_variables.each_key do |key|
      begin
        copy.instance_variable_set(key, self.instance_variable_get(key).clone)
      rescue TypeError  # For classes that can't be cloned (e.g. Fixnum).
        copy.instance_variable_set(key, self.instance_variable_get(key))
      end
    end

    # Since there does not seem to be a need for each clone to have its own,
    # separate DbcMethods, copies of the same DbcObject share the elements of
    # the dbc_methods array.
    copy.add_dbc_methods(*@dbc_methods)

    copy
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

  def has_equal_dbc_instance_variables?(other)
    @dbc_instance_variables.all? do |key, value|
      other.instance_variable_defined?(key) &&
        other.instance_variable_get(key) == self.instance_variable_get(key)
    end && other.dbc_instance_variables.all? do |key, value|
      self.instance_variable_defined?(key) &&
        self.instance_variable_get(key) == other.instance_variable_get(key)
    end
  end
end
