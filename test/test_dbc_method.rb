require_relative 'test_helpers'

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

  def test_has_accessible_percondition
    assert_respond_to @dbc_method, :precondition
    assert_respond_to @dbc_method, :precondition=
  end

  def test_has_accessible_postcondition
    assert_respond_to @dbc_method, :postcondition
    assert_respond_to @dbc_method, :postcondition=
  end
end
