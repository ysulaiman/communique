require_relative 'state'

class Planner
  attr_reader :initial_state, :plan
  attr_accessor :dbc_classes, :goal

  def initialize
    @initial_state = State.new('S0')
    @plan = []
    @dbc_classes = []
  end

  def set_up_initial_state(use_case)
    @initial_state.apply(&use_case.precondition)
  end

  def solve
    @plan = forward_search
  end

  def plan
    @plan.collect { |method| method.name }.join('; ')
  end

  private

  def forward_search
    state = @initial_state
    plan = []

    loop do
      return plan if state.satisfy?(&@goal)

      applicable_methods = find_applicable_methods(state)
      return :failure if applicable_methods.empty?

      method = applicable_methods.sample
      state = execute(state, method)
      plan << method
    end
  end

  def find_applicable_methods(state)
    all_methods = @dbc_classes.collect { |c| c.dbc_methods }.flatten
    all_methods.find_all { |m| state.satisfy?(&m.precondition) }
  end

  def execute(state, method)
    state.apply(&method.effect)
    state
  end
end
