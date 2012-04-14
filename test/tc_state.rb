require File.expand_path('../lib/state', File.dirname(__FILE__))
require 'minitest/autorun'

class TestState < MiniTest::Unit::TestCase
  def setup
    @state = State.new('S0')
  end

  def test_state_has_name
    assert_equal 'S0', @state.number
  end

  def test_state_has_variables
    @state.variables = {x: 13, y: 42, z: false}

    assert_equal 13, @state.variables[:x]
    assert_equal 42, @state.variables[:y]
    assert_equal false, @state.variables[:z]
  end
end
