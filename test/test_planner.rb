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
    assert_equal 'counter.change_value_from_42_to_43()', @planner.plan
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
    assert_equal 'user.log_in(username, password)', @planner.plan
  end

  def test_solves_non_trivial_problem
    user_instance = DbcObject.new('user', :User, {
      :@logged_in => false,
      :@activated => false
    })

    user_instance.add_dbc_methods(@parameterless_log_in, @log_out, @activate, @deactivate)

    @planner.initial_state.add(user_instance)
    @planner.goals = {'user' => Proc.new { @activated && !@logged_in }}

    @planner.solve
    assert_match /user.log_in\(\);.* user.activate\(\);.* user.log_out\(\)/,
                 @planner.plan
  end

  def test_solves_non_trivial_problem_deterministically
    user_instance = DbcObject.new('user', :User, {
      :@logged_in => false,
      :@activated => false
    })

    user_instance.add_dbc_methods(@parameterless_log_in, @log_out, @activate, @deactivate)

    @planner.initial_state.add(user_instance)
    @planner.goals = {'user' => Proc.new { @activated && !@logged_in }}
    @planner.algorithm = :depth_first_forward_search

    @planner.solve
    assert_equal "user.log_in(); user.activate(); user.log_out()", @planner.plan
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

    assert_equal 'counter.increment_by_3()', @planner.plan
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

    assert_equal 'counter.increment_by_3()', @planner.plan
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

    assert_equal 'counter_1.increment_by_1(); counter_2.increment_by_1()',
      @planner.plan
  end
end
