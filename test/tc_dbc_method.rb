require_relative '../lib/dbc_method'
require 'minitest/autorun'

class TestDbcMethod < MiniTest::Unit::TestCase
  def setup
    @dbc_method = DbcMethod.new('a_method')
  end

  def test_has_name
    assert_equal 'a_method', @dbc_method.name
  end

  def test_initially_has_empty_parameters_list
    assert @dbc_method.parameters.empty?
  end

  def test_can_have_multiple_parameters
    @dbc_method.parameters = {x: 13, y: 42}
    assert_equal 13, @dbc_method.parameters[:x]
    assert_equal 42, @dbc_method.parameters[:y]
  end

  def test_has_callable_percondition
    @dbc_method.precondition = -> { true }
    assert_equal true, @dbc_method.precondition.call
  end

  def test_has_callable_postcondition
    @dbc_method.postcondition = -> { x = 42 }
    assert_equal 42, @dbc_method.postcondition.call
  end
end
