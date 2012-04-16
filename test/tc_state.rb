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

  def test_can_check_if_it_satisfies_condition
    condition = -> { true }
    assert_equal true, @state.satisfy?(condition)

    condition = -> { false }
    assert_equal false, @state.satisfy?(condition)
  end
end
