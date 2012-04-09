require File.expand_path('../lib/dbc_method', File.dirname(__FILE__))
require 'test/unit'

class TestDbcMethod < Test::Unit::TestCase
  def setup
    @dbc_method = DbcMethod.new "a_method"
  end

  def test_dbc_method_has_name
    assert_equal "a_method", @dbc_method.name
  end

  def test_dbc_method_has_precondition
    @dbc_method.precondition = "true"
    assert_equal "true", @dbc_method.precondition
  end

  def test_dbc_method_has_postcondition
    @dbc_method.postcondition = "false"
    assert_equal "false", @dbc_method.postcondition
  end

  def test_precondition_evaluates_to_boolean
    @dbc_method.precondition = "1 + 1 == 2"
    assert_equal true, @dbc_method.evaluate_precondition

    @dbc_method.precondition = "1 + 1 == 3"
    assert_equal false, @dbc_method.evaluate_precondition
  end

  def test_postcondition_evaluates_to_boolean
    @dbc_method.postcondition = "1 + 1 == 2"
    assert_equal true, @dbc_method.evaluate_postcondition

    @dbc_method.postcondition = "1 + 1 == 3"
    assert_equal false, @dbc_method.evaluate_postcondition
  end
end
