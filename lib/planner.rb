require_relative 'state'

class Planner
  attr_reader :initial_state
  attr_accessor :algorithm, :goal

  def initialize(algorithm = :recursive_forward_search)
    @initial_state = State.new('S0')
    @algorithm = algorithm
    @plan = []
  end

  def set_up_initial_state(use_case)
    @initial_state.add(*use_case.dbc_instances)
  end

  def solve
    @dbc_methods = @initial_state.get_dbc_methods_of_instances

    @plan = case @algorithm
    when :randomized_forward_search
      randomized_forward_search
    when :recursive_forward_search
      recursive_forward_search(@initial_state, [])
    end
  end

  def plan
    @plan.collect { |method| create_sequence_diagram_ready_string(method) }.join('; ')
  end

  private

  def randomized_forward_search
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

  def recursive_forward_search(state, called_methods_names)
    return [] if state.satisfy?(&@goal)

    applicable_methods = find_applicable_methods(state, called_methods_names)
    return :failure if applicable_methods.empty?

    applicable_methods.each do |method|
      s0 = execute(state.clone, method)

      called_methods_copy = copy_called_methods_names(called_methods_names)
      called_methods_copy << method.name

      pi = recursive_forward_search(s0, called_methods_copy)
      if pi != :failure
        return pi.unshift(method)
      end
    end

    # Non of the applicable methods eventually lead to a goal state, so this
    # state is a dead end.
    return :failure
  end

  def find_applicable_methods(state, called_methods_names = nil)
    if called_methods_names.nil?
      @dbc_methods.find_all { |m| state.satisfy?(&m.precondition) }
    else
      @dbc_methods.find_all do |m|
        state.satisfy?(&m.precondition) &&
          ! called_methods_names.include?(m.name)
      end
    end
  end

  def execute(state, method)
    state.apply(method.receiver_name, &method.effect)
    state
  end

  def copy_called_methods_names(called_methods_names)
    copy = []
    called_methods_names.each { |method_name| copy << method_name }

    copy
  end

  def create_sequence_diagram_ready_string(method)
    "#{method.receiver_name.downcase}.#{method.name}(#{method.parameters.keys.join(', ')})"
  end
end
