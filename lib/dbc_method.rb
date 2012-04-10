class DbcMethod
  attr_accessor :name, :parameters, :precondition, :postcondition

  def initialize(name)
    self.name = name
  end

  def evaluate_precondition
    evaluate_condition(:pre)
  end

  def evaluate_postcondition
    evaluate_condition(:post)
  end

  private

  def evaluate_condition(type)
    result = case type
      when :pre
        eval self.precondition
      when :post
        eval self.postcondition
    end

    if !!result == result   # If result itself is boolean
      result
    else
      false
    end
  end
end
