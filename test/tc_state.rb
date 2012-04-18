require_relative '../lib/state'
require 'minitest/autorun'

class TestState < MiniTest::Unit::TestCase
  def setup
    @state = State.new('S0')
  end

  def test_state_has_name
    assert_equal 'S0', @state.name
  end

  def test_state_has_arbitrary_variables
    @state.x = 13
    @state.y = 42
    @state.z = false

    assert_equal 13, @state.x
    assert_equal 42, @state.y
    assert_equal false, @state.z
  end

  def test_can_check_if_it_satisfies_simple_conditions
    assert_equal true, @state.satisfy? { true }

    condition = Proc.new { false }
    assert_equal false, @state.satisfy?(&condition)

    @state.is_working = true
    assert_equal true, @state.satisfy? { is_working }
  end

  def test_can_check_if_it_satisfies_complex_conditions
    @state.x, @state.y = 42, 99
    assert_equal true, @state.satisfy? { x == 42 and y > x }
  end

  def test_does_not_satisfy_conditions_comparing_nonexistent_state_variables
    assert_equal false, @state.satisfy? { nonexistent_state_variable == 42 }
  end
end
