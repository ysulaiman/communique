require File.expand_path('../lib/dbc_class', File.dirname(__FILE__))
require 'test/unit'

class TestDbcClass < Test::Unit::TestCase
  def setup
    @dbc_class = DbcClass.new "AClass"
  end

  def test_dbc_class_has_name
    assert_equal "AClass", @dbc_class.name
  end

  def test_dbc_class_has_invariant
    @dbc_class.invariant = "true"
    assert_equal "true", @dbc_class.invariant
  end

  def test_dbc_class_invariant_evaluates_to_boolean
    @dbc_class.invariant = "42 == 42"
    assert_equal true, @dbc_class.evaluate_invariant
  end
end
