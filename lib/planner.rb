require_relative 'state'

class Planner
  attr_reader :initial_state
  attr_accessor :goal

  def initialize
    @initial_state = State.new('S0')
    @plan = []
  end

  def set_up_initial_state(use_case)
    @initial_state.add(*use_case.dbc_instances)
  end

  def solve
    @dbc_methods = @initial_state.get_dbc_methods_of_instances

    @plan = forward_search
  end

  def plan
    @plan.collect { |method| create_sequence_diagram_ready_string(method) }.join('; ')
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
    @dbc_methods.find_all { |m| state.satisfy?(&m.precondition) }
  end

  def execute(state, method)
    state.apply(method.receiver_name, &method.effect)
    state
  end

  def create_sequence_diagram_ready_string(method)
    "#{method.receiver_name.downcase}.#{method.name}(#{method.parameters.keys.join(', ')})"
  end
end
