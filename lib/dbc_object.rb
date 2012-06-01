class DbcObject
  attr_reader :dbc_name, :dbc_class

  def initialize(dbc_name, dbc_class, dbc_instance_variables)
    @dbc_name = dbc_name
    @dbc_class = dbc_class
    initialize_dbc_instance_variables(dbc_instance_variables)
  end

  def satisfy?(&condition)
    instance_eval &condition
  end

  def apply(&postcondition)
    instance_eval &postcondition
  end

  private

  def initialize_dbc_instance_variables(dbc_instance_variables)
    dbc_instance_variables.each do |name, value|
      instance_variable_set(name, value)
    end
  end
end
