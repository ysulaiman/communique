require_relative '../lib/action'
require 'minitest/autorun'

class TestAction < MiniTest::Unit::TestCase
  def setup
    @action = Action.new('an_action')
  end

  def test_has_name
    assert_equal 'an_action', @action.name
  end

  def test_initially_has_empty_parameters_list
    assert @action.parameters.empty?
  end

  def test_can_have_multiple_parameters
    @action.parameters = {x: 13, y: 42}
    assert_equal 13, @action.parameters[:x]
    assert_equal 42, @action.parameters[:y]
  end

  def test_has_callable_percondition
    @action.precondition = -> { true }
    assert_equal true, @action.precondition.call
  end

  def test_has_callable_effects
    @action.effect = -> { x = 42 }
    assert_equal 42, @action.effect.call
  end
end
