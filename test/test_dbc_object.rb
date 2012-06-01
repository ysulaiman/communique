require_relative 'test_helpers'

class TestDbcObject < MiniTest::Unit::TestCase
  def setup
    @dbc_object = DbcObject.new('account_instance', :Account, {:@number => 42})
  end

  def test_has_dbc_name
    assert_equal 'account_instance', @dbc_object.dbc_name
  end

  def test_has_dbc_class
    assert_equal :Account, @dbc_object.dbc_class
  end

  def test_can_check_if_it_satisfies_conditions
    assert_equal true, @dbc_object.satisfy? { @number == 42 }
  end

  def test_can_apply_postconditions_to_itself
    @dbc_object.apply { @number = 666 }
    assert_equal true, @dbc_object.satisfy? { @number == 666 }
  end
end
