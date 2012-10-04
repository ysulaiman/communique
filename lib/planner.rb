require_relative 'state'

class Planner
  attr_reader :initial_state
  attr_accessor :algorithm, :goals

  def initialize(algorithm = :breadth_first_forward_search)
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
    when :depth_first_forward_search
      depth_first_forward_search(@initial_state, [])
    when :breadth_first_forward_search
      breadth_first_forward_search
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
      return plan if state.satisfy?(@goals)

      applicable_methods = find_applicable_methods(state)
      return :failure if applicable_methods.empty?

      method = applicable_methods.sample
      state = execute(state, method)
      plan << method
    end
  end

  def depth_first_forward_search(state, called_methods_names)
    return [] if state.satisfy?(@goals)

    applicable_methods = find_applicable_methods(state, called_methods_names)
    return :failure if applicable_methods.empty?

    applicable_methods.each do |method|
      s0 = execute(state.clone, method)

      called_methods_copy = copy_called_methods_names(called_methods_names)
      called_methods_copy << method.name

      pi = depth_first_forward_search(s0, called_methods_copy)
      if pi != :failure
        return pi.unshift(method)
      end
    end

    # Non of the applicable methods eventually lead to a goal state, so this
    # state is a dead end.
    :failure
  end

  def breadth_first_forward_search
    queue = []
    queue.push([@initial_state.clone, []])

    until queue.empty?
      state, sequence_of_methods_leading_to_state = queue.shift
      return sequence_of_methods_leading_to_state if state.satisfy?(@goals)

      called_methods_names =
        sequence_of_methods_leading_to_state.collect { |method| method.name }
      applicable_methods = find_applicable_methods(state, called_methods_names)
      next if applicable_methods.empty?

      applicable_methods.each do |method|
        child_state = execute(state.clone, method)
        sequence_of_methods_leading_to_child_state =
          sequence_of_methods_leading_to_state.clone.push(method)
        queue.push([child_state, sequence_of_methods_leading_to_child_state])
      end
    end

    :failure
  end

  def find_applicable_methods(state, called_methods_names = nil)
    if called_methods_names.nil?
      @dbc_methods.find_all { |m| state.satisfy?({m.receiver_name => m.precondition}) }
    else
      @dbc_methods.find_all do |m|
        state.satisfy?({m.receiver_name => m.precondition}) &&
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
