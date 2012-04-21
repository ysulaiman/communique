class Planner
  attr_reader :initial_state, :plan
  attr_accessor :actions, :goal

  def initialize
    @initial_state = State.new('S0')
    @actions = []
    @plan = []
  end

  def solve
    applicable_action = find_applicable_action
    execute(applicable_action)
    @plan << applicable_action if goal_is_satisfied?
  end

  def plan
    @plan.collect { |action| action.name }.join(' ')
  end

  private

  def find_applicable_action
    @actions.find { |action| @initial_state.satisfy?(&action.precondition) }
  end

  def execute(action)
    @initial_state.apply(&action.effect)
  end

  def goal_is_satisfied?
    @initial_state.satisfy?(&@goal)
  end
end
