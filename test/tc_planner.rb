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
    a = Action.new
    b = Action.new
    c = Action.new
    @planner.actions = [a, b, c]

    assert_equal a, @planner.actions.first
    assert_equal c, @planner.actions.last
  end

  def test_solves_trivial_problem
    @planner.initial_state.x = 42
    @planner.goal = Proc.new { x == 43 }

    action = Action.new
    action.name = 'change_x_from_42_to_43'
    action.precondition = Proc.new { x == 42 }
    action.effect = Proc.new { |state| state.x = 43 }
    @planner.actions = [action]

    @planner.solve
    assert_equal 'change_x_from_42_to_43', @planner.plan
  end
end
