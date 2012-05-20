require_relative 'state'

class Planner
  attr_reader :initial_state, :plan
  attr_accessor :dbc_classes, :goal

  def initialize
    @initial_state = State.new('S0')
    @actions = []
    @plan = []
    @dbc_classes = []
  end

  def set_up_initial_state(use_case)
    @initial_state.apply(&use_case.precondition)
  end

  def solve
    @actions = @dbc_classes.collect { |c| c.dbc_methods}.flatten

    @plan = forward_search
  end

  def plan
    @plan.collect { |action| action.name }.join('; ')
  end

  private

  def forward_search
    state = @initial_state
    plan = []

    loop do
      return plan if state.satisfy?(&@goal)

      applicable_actions = find_applicable_actions(state)
      return :failure if applicable_actions.empty?

      action = applicable_actions.sample
      state = execute(state, action)
      plan << action
    end
  end

  def find_applicable_actions(state)
    @actions.find_all { |action| state.satisfy?(&action.precondition) }
  end

  def execute(state, action)
    state.apply(&action.effect)
    state
  end
end
