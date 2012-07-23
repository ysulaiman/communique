require_relative 'test_helpers'

class TestDbcObject < MiniTest::Unit::TestCase
  def setup
    @dbc_object = DbcObject.new('account_instance', :Account, {:@number => 42})
    @dbc_method = DbcMethod.new('dbc_method')
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

  def test_has_readable_dbc_methods
    assert_respond_to @dbc_object, :dbc_methods
  end

  def test_can_add_dbc_methods_to_itself
    @dbc_object.add_dbc_method(@dbc_method)

    assert_equal 'dbc_method', @dbc_object.dbc_methods.first.name
  end

  def test_set_receiver_name_of_dbc_methods_when_they_get_added
    @dbc_object.add_dbc_method(@dbc_method)

    assert_equal 'account_instance', @dbc_method.receiver_name
  end

  def test_has_accessors_for_its_instance_variables
    assert_equal 42, @dbc_object.number

    @dbc_object.number = 666
    assert_equal 666, @dbc_object.number
  end

  def test_instances_of_different_dbc_classes_have_different_accessors
    foo_instance = DbcObject.new('foo', :Foo, {:@foo => :foo})
    bar_instance = DbcObject.new('bar', :Bar, {:@bar => :bar})

    assert_respond_to foo_instance, :foo
    assert_respond_to foo_instance, :foo=
    refute_respond_to foo_instance, :bar
    refute_respond_to foo_instance, :bar=

    assert_respond_to bar_instance, :bar
    assert_respond_to bar_instance, :bar=
    refute_respond_to bar_instance, :foo
    refute_respond_to bar_instance, :foo=
  end
end
