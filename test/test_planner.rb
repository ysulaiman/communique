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

  def test_has_accessible_goal
    assert_respond_to @planner, :goal
    assert_respond_to @planner, :goal=
  end

  def test_solves_trivial_problem
    counter_instance = DbcObject.new('counter', :Counter, {:@value => 42})

    method = DbcMethod.new('change_value_from_42_to_43')
    method.precondition = Proc.new { @value == 42 }
    method.effect = Proc.new { @value = 43 }

    counter_instance.add_dbc_method(method)

    @planner.initial_state.add(counter_instance)
    @planner.goal = Proc.new { @value == 43 }

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
    log_in.precondition = Proc.new {
      log_in.parameters[:username] == @username &&
      log_in.parameters[:password] == @password &&
      !@logged_in
    }
    log_in.effect = Proc.new { @logged_in = true }

    user_instance.add_dbc_method(log_in)
    user_instance.add_dbc_method(@log_out)

    @planner.initial_state.add(user_instance)
    @planner.goal = Proc.new { @logged_in }

    @planner.solve
    assert_equal 'user.log_in(username, password)', @planner.plan
  end

  def test_solves_non_trivial_problem
    user_instance = DbcObject.new('user', :User, {
      :@logged_in => false,
      :@activated => false
    })

    user_instance.add_dbc_method(@parameterless_log_in)
    user_instance.add_dbc_method(@log_out)
    user_instance.add_dbc_method(@activate)
    user_instance.add_dbc_method(@deactivate)

    @planner.initial_state.add(user_instance)
    @planner.goal = Proc.new { @activated && !@logged_in}

    @planner.solve
    assert_match /user.log_in\(\);.* user.activate\(\);.* user.log_out\(\)/, @planner.plan
  end

  def test_can_use_dbc_use_case_to_set_up_initial_state
    skip('Need to figure out how use cases fit in the new picture of State')
    use_case = DbcUseCase.new('Login')
    use_case.precondition = Proc.new do |state|
      state.username = 'john'
      state.password = 'secret'
    end

    @planner.set_up_initial_state(use_case)
    assert @planner.initial_state.satisfy? { username == 'john' && password == 'secret' }
  end
end
