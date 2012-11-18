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
    number_of_objects_not_satisfying_their_conditions(conditions) == 0
  end

  def number_of_objects_not_satisfying_their_conditions(conditions)
    names_of_objects_not_satisfying_their_conditions(conditions).count
  end

  def names_of_objects_not_satisfying_their_conditions(conditions)
    unsatisfied_condition_pairs = conditions.select do |object_name, condition|
      ! object_satisfy?(object_name, &condition)
    end

    unsatisfied_condition_pairs.keys
  end

  def apply(dbc_object_name, &effect)
    dbc_object = @dbc_objects.find { |o| o.dbc_name == dbc_object_name }
    dbc_object.apply(&effect)
  end

  def include_instance_of?(dbc_class)
    @dbc_objects.any? { |dbc_object| dbc_object.dbc_class == dbc_class }
  end

  def include_instance_named?(dbc_name)
    @dbc_objects.any? { |object| object.dbc_name == dbc_name }
  end

  def get_instance_of(dbc_class)
    @dbc_objects.find { |object| object.dbc_class == dbc_class }
  end

  def get_instance_named(dbc_name)
    @dbc_objects.find { |object| object.dbc_name == dbc_name }
  end

  def get_dbc_methods_of_instances
    @dbc_objects.collect { |object| object.dbc_methods }.flatten
  end

  def clone
    clone_state = State.new(@name.clone)

    @dbc_objects.each do |object|
      unless clone_state.include_instance_named?(object.dbc_name)
        clone_object = object.clone
        clone_state.add(clone_object)

        sub_dbc_objects = clone_object.dbc_instance_variables.select do |k, v|
          v.is_a?(DbcObject)
        end

        sub_dbc_objects.each do |key, sub_object|
          existing_clone_sub_object =
            clone_state.get_instance_named(sub_object.dbc_name)
          if existing_clone_sub_object
            clone_object.instance_variable_set(key, existing_clone_sub_object)
          else
            clone_value = sub_object.clone
            clone_state.add(clone_value)
            clone_object.instance_variable_set(key, clone_value)
          end
        end
      end
    end

    clone_state
  end

  def dbc_objects_refering_to(dbc_object_name)
    return [] unless self.include_instance_named?(dbc_object_name)

    dbc_object_in_question = self.get_instance_named(dbc_object_name)

    @dbc_objects.find_all do |dbc_object|
      dbc_object.instance_variable_defined?("@#{dbc_object_name}") &&
        dbc_object_in_question == dbc_object.send(dbc_object_name)
    end
  end

  private

  def set_state_to_self(dbc_objects)
    dbc_objects.each { |object| object.state = self }
  end

  def object_satisfy?(object_name, &condition)
    dbc_object = @dbc_objects.find { |o| o.dbc_name == object_name }

    dbc_object.satisfy?(&condition)
  end
end
