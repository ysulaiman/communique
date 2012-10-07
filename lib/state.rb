require 'set'

class State
  attr_reader :name

  def initialize(name, dbc_objects = [])
    @name = name
    set_state_to_self(dbc_objects)
    @dbc_objects = dbc_objects.to_set
  end

  def add(*dbc_objects)
    set_state_to_self(dbc_objects)
    @dbc_objects.merge(dbc_objects)
  end

  def satisfy?(conditions)
    conditions.all? do |object_name, condition_block|
      dbc_object = @dbc_objects.find { |object| object.dbc_name == object_name }
      dbc_object.satisfy?(&condition_block)
    end
  end

  def apply(dbc_object_name, &effect)
    dbc_object = @dbc_objects.find { |dbc_object| dbc_object.dbc_name == dbc_object_name }
    dbc_object.apply(&effect)
  end

  def include_instance_of?(dbc_class)
    @dbc_objects.any? { |dbc_object| dbc_object.dbc_class == dbc_class }
  end

  def get_instance_of(dbc_class)
    @dbc_objects.find { |object| object.dbc_class == dbc_class }
  end

  def get_dbc_methods_of_instances
    @dbc_objects.collect { |object| object.dbc_methods }.flatten
  end

  def clone
    dbc_objects_copy = []
    @dbc_objects.each { |object| dbc_objects_copy << object.clone }

    State.new(@name.clone, dbc_objects_copy)
  end

  private

  def set_state_to_self(dbc_objects)
    dbc_objects.each { |object| object.state = self }
  end
end
