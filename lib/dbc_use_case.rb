class DbcUseCase
  attr_accessor :name, :precondition, :postcondition

  def initialize(name)
    @name = name
  end
end
