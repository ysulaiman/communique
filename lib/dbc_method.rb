class DbcMethod
  attr_accessor :name, :precondition, :postcondition

  def initialize(name)
    self.name = name
  end

  def evaluate_precondition
    eval self.precondition
  end

  def evaluate_postcondition
    eval self.postcondition
  end
end
