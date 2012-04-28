class DbcMethod
  attr_accessor :name, :parameters, :precondition, :postcondition

  alias_method :effect, :postcondition
  alias_method :effect=, :postcondition=

  def initialize(name, parameters={})
    @name = name
    @parameters = parameters
  end
end
