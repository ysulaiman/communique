require 'rubygems'
require 'depq'

require_relative 'state'

class Planner
  attr_reader :initial_state, :number_of_states_tested_for_goals, :plan,
    :unsatisfied_objects_names
  attr_accessor :algorithm, :goals

  def initialize(algorithm = :breadth_first_forward_search)
    @initial_state = State.new('S0')
    @algorithm = algorithm
    @number_of_states_tested_for_goals = 0
  end

  def set_up_initial_state(use_case)
    @initial_state.add(*use_case.dbc_instances)
  end

  def solve
    @number_of_states_tested_for_goals = 0
    @dbc_methods = @initial_state.get_dbc_methods_of_instances

    @plan = case @algorithm
    when :randomized_forward_search
      randomized_forward_search
    when :depth_first_forward_search
      depth_first_forward_search(@initial_state, [])
    when :breadth_first_forward_search
      breadth_first_forward_search
    when :best_first_forward_search
      best_first_forward_search
    end
  end

  private

  def randomized_forward_search
    state = @initial_state
    plan = []

    loop do
      @number_of_states_tested_for_goals += 1
      return plan if state.satisfy?(@goals)

      applicable_methods = find_applicable_methods(state)
      return :failure if applicable_methods.empty?

      method = applicable_methods.sample
      state = execute(state, method)
      plan << construct_method_call(method, plan, state)
    end
  end

  def depth_first_forward_search(state, called_methods_names)
    @number_of_states_tested_for_goals += 1
    return [] if state.satisfy?(@goals)

    applicable_methods = find_applicable_methods(state, called_methods_names)
    return :failure if applicable_methods.empty?

    applicable_methods.each do |method|
      s0 = execute(state.clone, method)

      # Use dependency relationships (if any) to make the needed <<create>>
      # method calls.
      create_method_call = nil
      method.dependencies.each do |dependency|
        s0.get_instance_named(dependency).dead = false
        create_method_call = {caller_name: method.receiver_name, method_name:
          '<<create>>', receiver_name: dependency}
      end

      called_methods_copy = copy_called_methods_names(called_methods_names)
      called_methods_copy << method.name

      pi = depth_first_forward_search(s0, called_methods_copy)
      if pi != :failure
        pi.unshift(create_method_call) if create_method_call
        return pi.unshift(construct_method_call(method, pi, state))
      end
    end

    # Non of the applicable methods eventually lead to a goal state, so this
    # state is a dead end.
    :failure
  end

  def breadth_first_forward_search
    queue = []
    queue.push([@initial_state.clone, []])

    # TODO: Keep track of best state seen so far?

    until queue.empty?
      state, sequence_of_method_calls_leading_to_state = queue.shift

      @number_of_states_tested_for_goals += 1
      return sequence_of_method_calls_leading_to_state if
        state.satisfy?(@goals)

      called_methods_names =
        sequence_of_method_calls_leading_to_state.collect { |m| m[:method_name] }
      applicable_methods = find_applicable_methods(state, called_methods_names)
      next if applicable_methods.empty?

      applicable_methods.each do |method|
        child_state = execute(state.clone, method)
        method_call = construct_method_call(method, sequence_of_method_calls_leading_to_state, state)
        sequence_of_method_calls_leading_to_child_state =
          sequence_of_method_calls_leading_to_state.clone.push(method_call)
        make_needed_create_method_calls(method, child_state, sequence_of_method_calls_leading_to_child_state)
        queue.push([child_state,
                   sequence_of_method_calls_leading_to_child_state])
      end
    end

    # All states were explored and none of them was a goal state.
    :failure
  end

  # TODO: DRY up breadth- and best-first search methods since they are high on
  # code duplication.
  def best_first_forward_search
    priority_queue = Depq.new
    node = [@initial_state.clone, []]
    priority_queue.insert(node, f(node))

    best_state_seen_so_far = @initial_state

    until priority_queue.empty?
      state, sequence_of_method_calls_leading_to_state =
        priority_queue.delete_min

      @number_of_states_tested_for_goals += 1
      return sequence_of_method_calls_leading_to_state if
        state.satisfy?(@goals)

      # The best state is the one closest to a goal state. That is, the state
      # that minimzes h(n) (the number of objects not satisfying their
      # conditions) as much as possible.
      best_state_seen_so_far = state if
        h(Array(state)) < h(Array(best_state_seen_so_far))

      applicable_methods = find_applicable_methods(state)

      delete_previously_called_methods_that_dont_improve_h(applicable_methods,
                                                           sequence_of_method_calls_leading_to_state,
                                                           state)
      next if applicable_methods.empty?

      applicable_methods.each do |method|
        child_state = execute(state.clone, method)
        method_call = construct_method_call(method, sequence_of_method_calls_leading_to_state, state)
        sequence_of_method_calls_leading_to_child_state =
          sequence_of_method_calls_leading_to_state.clone.push(method_call)
        make_needed_create_method_calls(method, child_state, sequence_of_method_calls_leading_to_child_state)
        node = [child_state, sequence_of_method_calls_leading_to_child_state]
        priority_queue.insert(node, f(node))
      end
    end

    # All states were explored and none of them was a goal state.

    @unsatisfied_objects_names =
      best_state_seen_so_far.names_of_objects_not_satisfying_their_conditions(@goals)

    :failure
  end

  # The evaluation, or objective, function
  def f(n)
    g(n) + h(n)
  end

  def g(n)
    sequence_of_method_calls_leading_to_state = n.last

    sequence_of_method_calls_leading_to_state.count
  end

  # The heuristic function
  def h(n)
    state = n.first

    state.number_of_objects_not_satisfying_their_conditions(@goals)
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

  def delete_previously_called_methods_that_dont_improve_h(applicable_methods,
                                                           sequence_of_method_calls_leading_to_state,
                                                           state)
    return if applicable_methods.empty? ||
      sequence_of_method_calls_leading_to_state.empty?

    called_methods_names =
      sequence_of_method_calls_leading_to_state.collect { |e| e[:method_name] }

    applicable_methods.delete_if do |method|
      child_state = execute(state.clone, method)

      called_methods_names.include?(method.name) &&
        h([child_state, nil]) >= h([state, nil])
    end
  end

  def construct_method_call(dbc_method, previous_method_calls, current_state)
    receiver_name = dbc_method.receiver_name
    parameters_names = dbc_method.parameters.keys
    caller_name = if previous_method_calls.empty?
                    # Assume that the actor always makes the first method call.
                    '<Actor>'
                  else
                    determine_caller_name(receiver_name, previous_method_calls,
                                          current_state)
                  end

    {caller_name: caller_name, method_name: dbc_method.name, parameters_names:
      parameters_names, receiver_name: receiver_name}
  end

  def determine_caller_name(current_receiver_name, previous_method_calls, current_state)
    # Assume that only the actor can call methods on boundary objects.
    return '<Actor>' if
      current_state.get_instance_named(current_receiver_name).boundary_object?

    # If the receiver is a dependency object (i.e. `<<create>>` was sent to it
    # at a previous point in time), assume that its creator is the only object
    # that can call its methods.
    relevant_create_method_call = previous_method_calls.find do |mc|
      mc[:method_name] == '<<create>>' &&
        mc[:receiver_name] == current_receiver_name
    end
    if relevant_create_method_call
      return relevant_create_method_call[:caller_name]
    end

    candidate_callers =
      current_state.dbc_objects_refering_to(current_receiver_name)

    # If a candidate caller doesn't have an active method on its lifeline (i.e.
    # no method was called on it), it can't actually be the caller.
    discard_inactive_candidate_callers(candidate_callers,
                                       previous_method_calls)

    if candidate_callers.empty?
      # If there are no active candidate callers, assume that the actor makes
      # the call.
      '<Actor>'
    elsif candidate_callers.size == 1
      candidate_callers.first.dbc_name
    else
      name_of_most_recently_activated_candidate_caller(candidate_callers,
                                                       previous_method_calls)
    end
  end

  def discard_inactive_candidate_callers(candidate_callers,
                                         previous_method_calls)
    candidate_callers.delete_if do |candidate_caller|
      previous_method_calls.none? do |method_call|
        method_call[:receiver_name] == candidate_caller.dbc_name
      end
    end
  end

  def name_of_most_recently_activated_candidate_caller(candidate_callers,
                                                       previous_method_calls)
    candidate_callers_names = candidate_callers.collect { |c| c.dbc_name }
    relevant_method_calls = previous_method_calls.select do |mc|
      candidate_callers_names.include?(mc[:receiver_name])
    end

    relevant_method_calls.last[:receiver_name]
  end

  def make_needed_create_method_calls(method, child_state, sequence_of_method_calls_leading_to_child_state)
    method.dependencies.each do |dependency|
      child_state.get_instance_named(dependency).dead = false
      sequence_of_method_calls_leading_to_child_state.push({
        caller_name: method.receiver_name,
        method_name: '<<create>>',
        receiver_name: dependency
      })
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
end
