class Action
  attr_accessor :name, :parameters, :precondition, :effect

  def initialize(name, parameters={})
    @name = name
    @parameters = parameters
  end
end
