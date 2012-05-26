require_relative 'test_helpers'

class TestPlanner < MiniTest::Unit::TestCase
  def setup
    @planner = Planner.new

    @parameterless_log_in = DbcMethod.new('log_in')
    @parameterless_log_in.precondition = Proc.new { !logged_in }
    @parameterless_log_in.effect = Proc.new { |state| state.logged_in = true }

    @log_out = DbcMethod.new('log_out')
    @log_out.precondition = Proc.new { logged_in }
    @log_out.effect = Proc.new { |state| state.logged_in = false }

    @activate = DbcMethod.new('activate')
    @activate.precondition = Proc.new { logged_in && !activated }
    @activate.effect = Proc.new { |state| state.activated = true }

    @deactivate = DbcMethod.new('deactivate')
    @deactivate.precondition = Proc.new { logged_in && activated }
    @deactivate.effect = Proc.new { |state| state.activated = false }
  end

  def test_has_accessible_initial_state
    @planner.initial_state.x = 42
    assert_equal 42, @planner.initial_state.x
  end

  def test_accepts_goal
    @planner.goal = Proc.new { x == 43 }
  end

  def test_has_accessible_dbc_classes
    assert_respond_to @planner, :dbc_classes
    assert_respond_to @planner, :dbc_classes=
  end

  def test_solves_trivial_problem
    @planner.initial_state.x = 42
    @planner.goal = Proc.new { x == 43 }

    method = DbcMethod.new('change_x_from_42_to_43')
    method.precondition = Proc.new { x == 42 }
    method.effect = Proc.new { |state| state.x = 43 }

    @dbc_class = DbcClass.new('Changer')
    @dbc_class.dbc_methods << method

    @planner.dbc_classes << @dbc_class

    @planner.solve
    assert_equal 'changer.change_x_from_42_to_43()', @planner.plan
  end

  def test_solves_trivial_problem_involving_multiple_actions_with_parameters
    @planner.initial_state.username = 'john'
    @planner.initial_state.password = 'secret'
    @planner.initial_state.logged_in = false
    @planner.goal = Proc.new { logged_in }

    log_in = DbcMethod.new('log_in')
    log_in.parameters = {username: 'john', password: 'secret'}
    log_in.precondition = Proc.new { log_in.parameters[:username] == username \
      && log_in.parameters[:password] == password && !logged_in }
    log_in.effect = Proc.new { |state| state.logged_in = true }

    @dbc_class = DbcClass.new('User')
    @dbc_class.dbc_methods << log_in << @log_out

    @planner.dbc_classes << @dbc_class

    @planner.solve
    assert_equal 'user.log_in(username, password)', @planner.plan
  end

  def test_solves_non_trivial_problem
    @planner.initial_state.logged_in = false
    @planner.initial_state.activated = false
    @planner.goal = Proc.new { activated && !logged_in}

    @user_dbc_class = DbcClass.new('User')
    @user_dbc_class.dbc_methods << @parameterless_log_in << @log_out << @activate << @deactivate

    @planner.dbc_classes << @user_dbc_class

    @planner.solve
    assert_match /user.log_in\(\);.* user.activate\(\);.* user.log_out\(\)/, @planner.plan
  end

  def test_can_use_dbc_use_case_to_set_up_initial_state
    use_case = DbcUseCase.new('Login')
    use_case.precondition = Proc.new do |state|
      state.username = 'john'
      state.password = 'secret'
    end

    @planner.set_up_initial_state(use_case)
    assert @planner.initial_state.satisfy? { username == 'john' && password == 'secret' }
  end
end
