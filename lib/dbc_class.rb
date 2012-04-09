class DbcClass
  attr_accessor :name, :invariant

  def initialize(name)
    self.name = name
  end

  def evaluate_invariant
    eval self.invariant
  end
end
