require_relative 'test_helpers'

class TestDbcMethod < MiniTest::Unit::TestCase
  def setup
    @dbc_method = DbcMethod.new('a_method', {x: 13, y: 42})
  end

  def test_has_name
    assert_equal 'a_method', @dbc_method.name
  end

  def test_initially_has_empty_parameters_list
    dbc_method = DbcMethod.new('dbc_method')
    assert dbc_method.parameters.empty?
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

  def test_has_accessible_receiver_name
    assert_respond_to @dbc_method, :receiver_name
    assert_respond_to @dbc_method, :receiver_name=
  end

  def test_equals_another_dbc_method_with_equal_name_and_parameters_and_receiver_name
    @dbc_method.receiver_name = 'dbc_object'
    equal_dbc_method = DbcMethod.new('a_method', {x: 13, y: 42})
    equal_dbc_method.receiver_name = 'dbc_object'

    assert_equal @dbc_method, equal_dbc_method
  end

  def test_does_not_equal_another_dbc_method_with_different_name
    dbc_method_with_different_name = DbcMethod.new('another_method', {x: 13, y: 42})

    refute_equal @dbc_method, dbc_method_with_different_name
  end

  def test_does_not_equal_another_dbc_method_with_different_parameters
    dbc_method_with_different_parameters = DbcMethod.new('a_method', {X: 31, Y: 24})

    refute_equal @dbc_method, dbc_method_with_different_parameters
  end

  def test_does_not_equal_another_dbc_method_with_different_receiver_name
    @dbc_method.receiver_name = 'dbc_object'
    dbc_method_with_different_receiver_name = DbcMethod.new('a_method', {x: 13, y: 42})
    dbc_method_with_different_receiver_name.receiver_name = 'another_dbc_object'

    refute_equal @dbc_method, dbc_method_with_different_receiver_name
  end
end
