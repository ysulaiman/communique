require_relative 'test_helpers'

class TestPlanner < MiniTest::Unit::TestCase
  def setup
    @planner = Planner.new

    @parameterless_log_in = DbcMethod.new('log_in')
    @parameterless_log_in.precondition = Proc.new { !@logged_in }
    @parameterless_log_in.effect = Proc.new { @logged_in = true }

    @log_out = DbcMethod.new('log_out')
    @log_out.precondition = Proc.new { @logged_in }
    @log_out.effect = Proc.new { @logged_in = false }

    @activate = DbcMethod.new('activate')
    @activate.precondition = Proc.new { @logged_in && !@activated }
    @activate.effect = Proc.new { @activated = true }

    @deactivate = DbcMethod.new('deactivate')
    @deactivate.precondition = Proc.new { @logged_in && @activated }
    @deactivate.effect = Proc.new { @activated = false }

    @actor_name = '<Actor>'
  end

  def test_has_readable_initial_state
    assert_respond_to @planner, :initial_state
  end

  def test_has_accessible_goals
    assert_respond_to @planner, :goals
    assert_respond_to @planner, :goals=
  end

  def test_has_accessible_algorithm
    @planner.algorithm = :randomized_forward_search

    assert_equal :randomized_forward_search, @planner.algorithm
  end

  def test_has_initial_default_algorithm
    assert_equal :breadth_first_forward_search, @planner.algorithm
  end

  def test_can_be_initialized_with_a_specific_algorithm
    planner = Planner.new(:depth_first_forward_search)

    assert_equal :depth_first_forward_search, planner.algorithm
  end

  def test_solves_trivial_problem
    counter_instance = DbcObject.new('counter', :Counter, {:@value => 42})

    method = DbcMethod.new('change_value_from_42_to_43')
    method.precondition = Proc.new { @value == 42 }
    method.effect = Proc.new { @value = 43 }

    counter_instance.add_dbc_methods(method)

    @planner.initial_state.add(counter_instance)
    @planner.goals = {'counter' => Proc.new { @value == 43 }}

    @planner.solve

    assert_equal 1, @planner.plan.length
    assert_equal @actor_name, @planner.plan.first[:caller_name]
    assert_equal method.name, @planner.plan.first[:method_name]
    assert_equal counter_instance.dbc_name, @planner.plan.first[:receiver_name]
  end

  def test_solves_trivial_problem_involving_multiple_actions_with_parameters
    user_instance = DbcObject.new('user', :User, {
      :@username => 'john',
      :@password => 'secret',
      :@logged_in => false
    })

    log_in = DbcMethod.new('log_in')
    log_in.parameters = {username: 'john', password: 'secret'}
    log_in.precondition = Proc.new do
      log_in.parameters[:username] == @username &&
      log_in.parameters[:password] == @password &&
      !@logged_in
    end
    log_in.effect = Proc.new { @logged_in = true }

    user_instance.add_dbc_methods(log_in, @log_out)

    @planner.initial_state.add(user_instance)
    @planner.goals = {'user' => Proc.new { @logged_in }}

    @planner.solve

    assert_equal 1, @planner.plan.length
    assert_equal @actor_name, @planner.plan.first[:caller_name]
    assert_equal log_in.name, @planner.plan.first[:method_name]
    assert_equal log_in.parameters.keys, @planner.plan.first[:parameters_names]
    assert_equal user_instance.dbc_name, @planner.plan.first[:receiver_name]
  end

  def test_solves_non_trivial_problem_deterministically
    user_instance = DbcObject.new('user', :User, {
      :@logged_in => false,
      :@activated => false
    })

    user_instance.add_dbc_methods(@parameterless_log_in, @log_out, @activate,
                                  @deactivate)

    @planner.initial_state.add(user_instance)
    @planner.goals = {'user' => Proc.new { @activated && !@logged_in }}
    @planner.algorithm = :breadth_first_forward_search

    @planner.solve
    plan = @planner.plan

    assert_equal 3, plan.length

    first_method_call = plan.first
    second_method_call = plan[1]
    third_method_call = plan.last

    assert_equal @actor_name, first_method_call[:caller_name]
    assert_equal @parameterless_log_in.name, first_method_call[:method_name]
    assert_equal user_instance.dbc_name, first_method_call[:receiver_name]

    assert_equal @actor_name, second_method_call[:caller_name]
    assert_equal @activate.name, second_method_call[:method_name]
    assert_equal user_instance.dbc_name, second_method_call[:receiver_name]

    assert_equal @actor_name, third_method_call[:caller_name]
    assert_equal @log_out.name, third_method_call[:method_name]
    assert_equal user_instance.dbc_name, third_method_call[:receiver_name]
  end

  def test_finds_shortest_plan_when_using_breadth_first_search
    counter_instance = DbcObject.new('counter', :Counter, {:@value => 0})

    increment_by_1 = DbcMethod.new('increment_by_1')
    increment_by_1.precondition = Proc.new { true }
    increment_by_1.effect = Proc.new { @value += 1 }

    increment_by_2 = DbcMethod.new('increment_by_2')
    increment_by_2.precondition = Proc.new { true }
    increment_by_2.effect = Proc.new { @value += 2 }

    increment_by_3 = DbcMethod.new('increment_by_3')
    increment_by_3.precondition = Proc.new { true }
    increment_by_3.effect = Proc.new { @value += 3 }

    counter_instance.add_dbc_methods(increment_by_1, increment_by_2,
                                     increment_by_3)

    @planner.initial_state.add(counter_instance)
    @planner.goals = {'counter' => Proc.new { @value == 3 }}
    @planner.algorithm = :breadth_first_forward_search

    @planner.solve

    assert_equal 1, @planner.plan.length
    assert_equal @actor_name, @planner.plan.first[:caller_name]
    assert_equal increment_by_3.name, @planner.plan.first[:method_name]
    assert_equal counter_instance.dbc_name, @planner.plan.first[:receiver_name]
  end

  def test_reduces_number_of_explored_states_when_using_best_first_search
    counter_instance = DbcObject.new('counter', :Counter, {:@value => 0})

    increment_by_1 = DbcMethod.new('increment_by_1')
    increment_by_1.precondition = Proc.new { true }
    increment_by_1.effect = Proc.new { @value += 1 }

    increment_by_2 = DbcMethod.new('increment_by_2')
    increment_by_2.precondition = Proc.new { true }
    increment_by_2.effect = Proc.new { @value += 2 }

    increment_by_3 = DbcMethod.new('increment_by_3')
    increment_by_3.precondition = Proc.new { true }
    increment_by_3.effect = Proc.new { @value += 3 }

    counter_instance.add_dbc_methods(increment_by_1, increment_by_2,
                                     increment_by_3)

    @planner.initial_state.add(counter_instance)
    @planner.goals = {'counter' => Proc.new { @value == 3 }}
    @planner.algorithm = :best_first_forward_search

    @planner.solve

    assert_equal 1, @planner.plan.length
    assert_equal @actor_name, @planner.plan.first[:caller_name]
    assert_equal increment_by_3.name, @planner.plan.first[:method_name]
    assert_equal counter_instance.dbc_name, @planner.plan.first[:receiver_name]

    assert_equal 2, @planner.number_of_states_tested_for_goals
  end

  def test_can_use_dbc_use_case_to_set_up_initial_state
    user_instance = DbcObject.new('user', :User, {
      :@username => 'john',
      :@password => 'secret'
    })
    use_case = DbcUseCase.new('Login')
    use_case.dbc_instances << user_instance

    @planner.set_up_initial_state(use_case)
    assert @planner.initial_state.satisfy?({
      'user' => Proc.new { @username == 'john' && @password == 'secret' }
    })
  end

  def test_has_readable_number_of_states_tested_for_goals
    assert_respond_to @planner, :number_of_states_tested_for_goals
  end

  def test_sets_plan_to_failure_symbol_when_it_fails_to_solve_the_problem
    switch_instance = DbcObject.new('switch', :Switch, {:@is_on => false})

    useless_method = DbcMethod.new(:no_operation)
    useless_method.precondition = Proc.new { true }
    useless_method.effect = Proc.new {}

    switch_instance.add_dbc_methods(useless_method)

    @planner.initial_state.add(switch_instance)
    @planner.goals = {'switch' => Proc.new { @is_on }}

    @planner.solve

    assert_equal :failure, @planner.plan
  end

  def test_can_report_names_of_unsatisfied_objects_upon_failure
    a = DbcObject.new('a', :A, {:@is_satisfied => false})
    b = DbcObject.new('b', :B, {:@is_satisfied => false})
    c = DbcObject.new('c', :C, {:@is_satisfied => false})

    satisfy_a = DbcMethod.new(:satisfy_a)
    satisfy_a.precondition = Proc.new { true }
    satisfy_a.postcondition = Proc.new { @is_satisfied = true }
    a.add_dbc_methods(satisfy_a)

    satisfy_b = DbcMethod.new(:satisfy_b)
    satisfy_b.precondition = Proc.new { true }
    satisfy_b.postcondition = Proc.new { @is_satisfied = true }
    b.add_dbc_methods(satisfy_b)

    @planner.initial_state.add(a, b, c)
    @planner.goals = {
      'a' => Proc.new { @is_satisfied },
      'b' => Proc.new { @is_satisfied },
      'c' => Proc.new { @is_satisfied }
    }
    @planner.algorithm = :best_first_forward_search

    @planner.solve
    assert_equal :failure, @planner.plan
    assert_equal [c.dbc_name], @planner.unsatisfied_objects_names
  end

  def test_best_first_allows_multiple_same_name_messages_if_each_improves_h
    counter_1_instance = DbcObject.new('counter_1', :Counter, {:@value => 0})
    counter_2_instance = DbcObject.new('counter_2', :Counter, {:@value => 0})

    increment_counter_1_by_1 = DbcMethod.new(:increment_by_1)
    increment_counter_1_by_1.precondition = Proc.new { true }
    increment_counter_1_by_1.effect = Proc.new { @value += 1 }

    increment_counter_2_by_1 = DbcMethod.new(:increment_by_1)
    increment_counter_2_by_1.precondition = Proc.new { true }
    increment_counter_2_by_1.effect = Proc.new { @value += 1 }

    counter_1_instance.add_dbc_methods(increment_counter_1_by_1)
    counter_2_instance.add_dbc_methods(increment_counter_2_by_1)

    @planner.initial_state.add(counter_1_instance, counter_2_instance)
    @planner.goals = {
      'counter_1' => Proc.new { @value == 1 },
      'counter_2' => Proc.new { @value == 1 },
    }
    @planner.algorithm = :best_first_forward_search

    @planner.solve
    plan = @planner.plan

    assert_equal 2, plan.length

    first_method_call = plan.first
    second_method_call = plan.last

    assert_equal @actor_name, first_method_call[:caller_name]
    assert_equal increment_counter_1_by_1.name, first_method_call[:method_name]
    assert_equal counter_1_instance.dbc_name, first_method_call[:receiver_name]

    assert_equal @actor_name, second_method_call[:caller_name]
    assert_equal increment_counter_2_by_1.name,
      second_method_call[:method_name]
    assert_equal counter_2_instance.dbc_name,
      second_method_call[:receiver_name]
  end

  def test_assumes_the_actor_is_the_caller_for_the_first_method_call
    receiver = DbcObject.new('receiver', :Receiver, {})
    incorrect_caller = DbcObject.new('incorrect_caller', :IncorrectCaller, {
      :@receiver => receiver
    })
    @planner.initial_state.add(receiver, incorrect_caller)

    current_receiver_name = receiver.dbc_name
    previous_method_calls = []
    caller_name = @planner.send(:determine_caller_name, current_receiver_name,
                                previous_method_calls, @planner.initial_state)

    assert_equal @actor_name, caller_name
  end

  def test_selects_the_most_recently_activated_candidate_caller_if_there_are_more_than_one
    receiver = DbcObject.new('receiver', :Receiver, {})
    correct_caller = DbcObject.new('correct_caller', :CorrectCaller, {
      :@receiver => receiver
    })
    incorrect_caller = DbcObject.new('incorrect_caller', :IncorrectCaller, {
      :@receiver => receiver
    })

    @planner.initial_state.add(receiver, correct_caller, incorrect_caller)

    current_receiver_name = receiver.dbc_name
    previous_method_calls = [
      {caller_name: '<Actor>', method_name: :m_1,
        receiver_name: incorrect_caller.dbc_name},
      {caller_name: '<Actor>', method_name: :m_2,
        receiver_name: correct_caller.dbc_name},
    ]

    caller_name = @planner.send(:determine_caller_name, current_receiver_name,
                                previous_method_calls, @planner.initial_state)

    assert_equal correct_caller.dbc_name, caller_name
  end

  def test_regards_methods_of_dbc_objects_that_are_marked_as_dead_as_inapplicable
    object = DbcObject.new('object', :Class, {})
    object.dead = true

    method = DbcMethod.new(:m)
    method.precondition = Proc.new { true }
    method.postcondition = Proc.new {}
    object.add_dbc_methods(method)

    @planner.initial_state.add(object)
    @planner.instance_variable_set(:@dbc_methods, [method])

    applicable_methods = @planner.send(:find_applicable_methods,
                                       @planner.initial_state)
    assert_empty applicable_methods
  end

  def test_uses_dependency_relationships_to_instantiate_needed_objects
    sequence_diagram_generator = DbcObject.new('sequence_diagram_generator',
                                               :SequenceDiagramGenerator, {})
    planner = DbcObject.new('planner', :Planner, {:@is_done_solving => false})
    planner.dead = true

    generate = DbcMethod.new(:generate)
    generate.precondition = Proc.new { true }
    generate.postcondition = Proc.new {}
    generate.dependencies.push(planner.dbc_name)
    sequence_diagram_generator.add_dbc_methods(generate)

    solve = DbcMethod.new(:solve)
    solve.precondition = Proc.new { true }
    solve.postcondition = Proc.new { @is_done_solving = true }
    planner.add_dbc_methods(solve)

    @planner.initial_state.add(sequence_diagram_generator, planner)
    @planner.goals = {'planner' => Proc.new { @is_done_solving }}
    @planner.algorithm = :best_first_forward_search

    @planner.solve
    plan = @planner.plan

    refute_equal :failure, plan
    assert_equal 3, plan.length

    first_method_call = plan.first
    second_method_call = plan[1]
    third_method_call = plan.last

    assert_equal @actor_name, first_method_call[:caller_name]
    assert_equal generate.name, first_method_call[:method_name]
    assert_equal sequence_diagram_generator.dbc_name,
      first_method_call[:receiver_name]

    assert_equal sequence_diagram_generator.dbc_name,
      second_method_call[:caller_name]
    assert_equal '<<create>>', second_method_call[:method_name]
    assert_equal planner.dbc_name, second_method_call[:receiver_name]

    assert_equal sequence_diagram_generator.dbc_name, third_method_call[:caller_name]
    assert_equal solve.name, third_method_call[:method_name]
    assert_equal planner.dbc_name, third_method_call[:receiver_name]
  end
end
