class State
  attr_accessor :name, :variables

  def initialize(name)
    @name = name
  end

  def satisfy?(condition)
    condition.call
  end
end
