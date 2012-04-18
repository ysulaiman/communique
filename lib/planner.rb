class Planner
  attr_reader :initial_state, :plan
  attr_accessor :actions, :goal

  def initialize
    @initial_state = State.new('S0')
    @actions = []
    @plan = []
  end

  def solve
    applicable_action = @actions.find { |action| @initial_state.satisfy?(&action.precondition) }
    @initial_state.instance_eval(&applicable_action.effect)
    @plan << applicable_action if @initial_state.instance_eval(&@goal)
  end

  def plan
    @plan.collect { |action| action.name }.join(' ')
  end
end
