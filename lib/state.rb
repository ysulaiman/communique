require 'set'

class State
  attr_reader :name

  def initialize(name, dbc_objects = [])
    @name = name
    @dbc_objects = dbc_objects.to_set
  end

  def add(dbc_object)
    @dbc_objects.add(dbc_object)
  end

  def satisfy?(&condition)
    @dbc_objects.any? { |dbc_object| dbc_object.satisfy?(&condition) }
  end

  def apply(dbc_object_name, &effect)
    dbc_object = @dbc_objects.find { |dbc_object| dbc_object.dbc_name == dbc_object_name }
    dbc_object.instance_eval(&effect)
  end

  def include_instance_of?(dbc_class)
    @dbc_objects.any? { |dbc_object| dbc_object.dbc_class == dbc_class }
  end

  def get_dbc_methods_of_instances
    @dbc_objects.collect { |obj| obj.dbc_methods }.flatten
  end
end
