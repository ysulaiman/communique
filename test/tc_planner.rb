require_relative '../lib/planner'
require 'minitest/autorun'

class TestPlanner < MiniTest::Unit::TestCase
  def setup
    @planner = Planner.new
  end

  def test_has_initial_state
    @planner.initial_state.x = 42
    assert_equal 42, @planner.initial_state.x
  end

  def test_accepts_goal
    @planner.goal = Proc.new { x == 43 }
  end

  def test_accepts_actions
    a = Action.new('a')
    b = Action.new('b')
    c = Action.new('c')
    @planner.actions = [a, b, c]

    assert_equal a, @planner.actions.first
    assert_equal c, @planner.actions.last
  end

  def test_solves_trivial_problem
    @planner.initial_state.x = 42
    @planner.goal = Proc.new { x == 43 }

    action = Action.new('change_x_from_42_to_43')
    action.precondition = Proc.new { x == 42 }
    action.effect = Proc.new { |state| state.x = 43 }
    @planner.actions = [action]

    @planner.solve
    assert_equal 'change_x_from_42_to_43', @planner.plan
  end

  def test_solves_trivial_problem_involving_multiple_actions_with_parameters
    @planner.initial_state.username = 'john'
    @planner.initial_state.password = 'secret'
    @planner.initial_state.logged_in = false
    @planner.goal = Proc.new { logged_in }

    log_in = Action.new('log_in')
    log_in.parameters = {username: 'john', password: 'secret'}
    log_in.precondition = Proc.new { log_in.parameters[:username] == username \
      && log_in.parameters[:password] == password && !logged_in }
    log_in.effect = Proc.new { |state| state.logged_in = true }
    @planner.actions << log_in

    log_out = Action.new('log_out')
    log_out.precondition = Proc.new { logged_in }
    log_out.effect = Proc.new { |state| state.logged_in = false }
    @planner.actions << log_out

    @planner.solve
    assert_equal 'log_in', @planner.plan
  end

  def test_solves_non_trivial_problem
    @planner.initial_state.logged_in = false
    @planner.initial_state.activated = false
    @planner.goal = Proc.new { activated && !logged_in}

    log_in = Action.new('log_in')
    log_in.precondition = Proc.new { !logged_in }
    log_in.effect = Proc.new { |state| state.logged_in = true }
    @planner.actions << log_in

    log_out = Action.new('log_out')
    log_out.precondition = Proc.new { logged_in }
    log_out.effect = Proc.new { |state| state.logged_in = false }
    @planner.actions << log_out

    activate = Action.new('activate')
    activate.precondition = Proc.new { logged_in && !activated }
    activate.effect = Proc.new { |state| state.activated = true }
    @planner.actions << activate

    deactivate = Action.new('deactivate')
    deactivate.precondition = Proc.new { logged_in && activated }
    deactivate.effect = Proc.new { |state| state.activated = false }
    @planner.actions << deactivate

    @planner.solve
    assert_match /log_in;.* activate;.* log_out/, @planner.plan
  end
end
