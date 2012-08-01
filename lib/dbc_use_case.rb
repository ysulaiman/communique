class DbcUseCase
  attr_accessor :name, :dbc_instances, :postcondition

  def initialize(name)
    @name = name
    @dbc_instances = []
  end

  def reset_dbc_instances
    @dbc_instances.each { |instance| instance.reset_instance_variables }
  end
end
