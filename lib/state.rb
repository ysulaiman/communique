class State
  attr_reader :name

  def initialize(name, dbc_objects = [])
    @name = name
    set_state_to_self(dbc_objects)
    @dbc_objects = Hash[dbc_objects.map { |e| [e.dbc_name, e] }]
  end

  def add(*dbc_objects)
    set_state_to_self(dbc_objects)
    @dbc_objects.update(Hash[dbc_objects.map { |e| [e.dbc_name, e] }])
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
    dbc_object = @dbc_objects[dbc_object_name]
    dbc_object.apply(&effect)
  end

  def include_instance_of?(dbc_class)
    @dbc_objects.values.any? { |dbc_object| dbc_object.dbc_class == dbc_class }
  end

  def include_instance_named?(dbc_name)
    @dbc_objects.key?(dbc_name)
  end

  def get_instance_of(dbc_class)
    @dbc_objects.values.find { |object| object.dbc_class == dbc_class }
  end

  def get_instance_named(dbc_name)
    @dbc_objects[dbc_name]
  end

  def get_dbc_methods_of_instances
    @dbc_objects.values.collect { |object| object.dbc_methods }.flatten
  end

  def clone
    clone_state = State.new(@name.clone)

    @dbc_objects.values.each do |object|
      unless clone_state.include_instance_named?(object.dbc_name)
        clone_object = object.clone
        clone_state.add(clone_object)

        sub_dbc_objects = Hash.new
        object.dbc_instance_variables.keys.each do |key|
          sub_dbc_object = object.instance_variable_get(key)
          if sub_dbc_object.is_a?(DbcObject)
            sub_dbc_objects[key] = sub_dbc_object
          end
        end

        sub_dbc_objects.each do |key, sub_object|
          # Clone the sub-object unless it was already cloned before.
          unless clone_sub_object = clone_state.get_instance_named(sub_object.dbc_name)
            clone_sub_object = sub_object.clone
            clone_state.add(clone_sub_object)
          end
          # Make the clone of object point to the clone of sub-object in the
          # cloned state.
          clone_object.instance_variable_set(key, clone_sub_object)

          # If the sub-object pointed back to object in original state, make
          # the clone of sub-object point to the clone of object in the cloned
          # state.
          backlinks = sub_object.dbc_instance_variables.keys.find_all do |k|
            pointed_to_object = sub_object.instance_variable_get(k)

            pointed_to_object && pointed_to_object.equal?(object)
          end

          backlinks.each do |backlink|
            clone_sub_object.instance_variable_set(backlink, clone_object)
          end
        end
      end
    end

    clone_state
  end

  def dbc_objects_refering_to(dbc_object_name)
    return [] unless self.include_instance_named?(dbc_object_name)

    dbc_object_in_question = self.get_instance_named(dbc_object_name)

    @dbc_objects.values.find_all do |dbc_object|
      dbc_object.instance_variable_defined?("@#{dbc_object_name}") &&
        dbc_object_in_question == dbc_object.send(dbc_object_name)
    end
  end

  private

  def set_state_to_self(dbc_objects)
    dbc_objects.each { |object| object.state = self }
  end

  def object_satisfy?(object_name, &condition)
    dbc_object = @dbc_objects[object_name]

    dbc_object.satisfy?(&condition)
  end
end
