require_relative 'test_helpers'

class TestDbcObject < MiniTest::Unit::TestCase
  def setup
    @dbc_object = DbcObject.new('account_instance', :Account, {:@number => 42})
    @dbc_method = DbcMethod.new('dbc_method')

    @foo_instance = DbcObject.new('foo', :Foo, {:@foo => :foo})
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
    @dbc_object.add_dbc_methods(@dbc_method)

    assert_equal 'dbc_method', @dbc_object.dbc_methods.first.name
  end

  def test_set_receiver_name_of_dbc_methods_when_they_get_added
    @dbc_object.add_dbc_methods(@dbc_method)

    assert_equal 'account_instance', @dbc_method.receiver_name
  end

  def test_can_add_multiple_dbc_methods_and_set_their_names_in_one_call
    m1 = DbcMethod.new('m1')
    m2 = DbcMethod.new('m2')
    m3 = DbcMethod.new('m3')
    @dbc_object.add_dbc_methods(m1, m2, m3)

    assert_equal 3, @dbc_object.dbc_methods.size

    assert_equal 'account_instance', m1.receiver_name
    assert_equal 'account_instance', m2.receiver_name
    assert_equal 'account_instance', m3.receiver_name
  end

  def test_has_accessors_for_its_instance_variables
    assert_equal 42, @dbc_object.number

    @dbc_object.number = 666
    assert_equal 666, @dbc_object.number
  end

  def test_instances_of_different_dbc_classes_have_different_accessors
    bar_instance = DbcObject.new('bar', :Bar, {:@bar => :bar})

    assert_respond_to @foo_instance, :foo
    assert_respond_to @foo_instance, :foo=
    refute_respond_to @foo_instance, :bar
    refute_respond_to @foo_instance, :bar=

    assert_respond_to bar_instance, :bar
    assert_respond_to bar_instance, :bar=
    refute_respond_to bar_instance, :foo
    refute_respond_to bar_instance, :foo=
  end

  def test_can_reset_its_instance_variables_to_their_initial_values
    @dbc_object.number = 666
    @dbc_object.reset_instance_variables

    assert_equal 42, @dbc_object.number
  end

  def test_reset_its_dbc_objects_in_the_process_of_resetting_itself
    foo_instance = DbcObject.new('foo', :Foo, {:@number => 42})
    bar_instance = DbcObject.new('bar', :Bar, {:@foo => foo_instance})

    bar_instance.foo.number = 666
    bar_instance.reset_instance_variables

    assert_equal 42, bar_instance.foo.number
    assert_equal 42, foo_instance.number
  end

  def test_equals_another_dbc_object_with_equal_dbc_name_and_class_and_instance_variables
    equal_foo_instance = DbcObject.new('foo', :Foo, {:@foo => :foo})
    assert_equal @foo_instance, equal_foo_instance

    @foo_instance.foo = 'bar'
    equal_foo_instance.foo = 'bar'

    assert_equal @foo_instance, equal_foo_instance
  end

  def test_equals_another_equal_dbc_object_with_equal_dbc_methods
    @foo_instance.add_dbc_methods(DbcMethod.new('dbc_method'))
    equal_foo_instance = DbcObject.new('foo', :Foo, {:@foo => :foo})

    equal_foo_instance.add_dbc_methods(DbcMethod.new('dbc_method'))

    assert_equal @foo_instance, equal_foo_instance
  end

  def test_does_not_equal_another_dbc_objec_with_different_dbc_name
    foo_instance_with_different_name = DbcObject.new('baz', :Foo, {:@foo => :foo})

    refute_equal @foo_instance, foo_instance_with_different_name
  end

  def test_does_not_equal_another_dbc_objec_with_different_dbc_class
    foo_instance_with_different_class = DbcObject.new('foo', :Baz, {:@foo => :foo})

    refute_equal @foo_instance, foo_instance_with_different_class
  end

  def test_does_not_equal_another_dbc_objec_with_different_dbc_instance_variables_names
    foo_instance_with_different_instance_variables_names = DbcObject.new('foo', :Foo, {:@baz => :foo})

    refute_equal @foo_instance, foo_instance_with_different_instance_variables_names
  end

  def test_does_not_equal_another_dbc_objec_with_different_dbc_instance_variables_values
    foo_instance_with_different_instance_variables_values = DbcObject.new('foo', :Foo, {:@foo => :foo})
    foo_instance_with_different_instance_variables_values.foo = :bar

    refute_equal @foo_instance, foo_instance_with_different_instance_variables_values
  end

  def test_does_not_equal_another_dbc_objec_with_different_dbc_methods
    @foo_instance.add_dbc_methods(DbcMethod.new('method'))
    foo_instance_with_different_dbc_methods = DbcObject.new('foo', :Foo, {:@foo => :fpp})
    foo_instance_with_different_dbc_methods.add_dbc_methods(DbcMethod.new('another_method'))

    refute_equal @foo_instance, foo_instance_with_different_dbc_methods
  end

  def test_can_be_deep_copied
    new_dbc_object = @dbc_object.clone

    assert_equal @dbc_object, new_dbc_object
    refute new_dbc_object.equal?(@dbc_object)
    refute new_dbc_object.dbc_name.equal?(@dbc_object.dbc_name)
    refute new_dbc_object.dbc_instance_variables.equal?(@dbc_object.dbc_instance_variables)
  end

  def test_copies_current_values_of_dbc_instance_variables
    @dbc_object.number = 'Fourty Two'
    new_dbc_object = @dbc_object.clone

    assert_equal @dbc_object.number, new_dbc_object.number
    refute new_dbc_object.number.equal?(@dbc_object.number)
  end

  def test_copies_its_dbc_methods_in_the_process_of_deep_copying_itself
    @dbc_object.add_dbc_methods(@dbc_method)
    new_dbc_object = @dbc_object.clone

    assert_equal @dbc_object.dbc_methods, new_dbc_object.dbc_methods
  end

  def test_handles_dbc_instance_variables_that_cannot_be_cloned
    @dbc_object.number = 666
    new_dbc_object = @dbc_object.clone

    assert_equal 666, new_dbc_object.number
  end

  def test_deep_copies_its_dbc_objects_in_the_process_of_deep_copying_itself
    foo_instance = DbcObject.new('foo', :Foo, {:@number => 42})
    bar_instance = DbcObject.new('bar', :Bar, {:@foo => foo_instance})
    baz_instance = DbcObject.new('baz', :Baz, {:@bar => bar_instance})

    new_baz_instance = baz_instance.clone

    assert_equal baz_instance, new_baz_instance
    refute new_baz_instance.equal?(baz_instance)

    assert_equal baz_instance.bar, new_baz_instance.bar
    refute new_baz_instance.bar.equal?(baz_instance.bar)

    assert_equal baz_instance.bar.foo, new_baz_instance.bar.foo
    refute new_baz_instance.bar.foo.equal?(baz_instance.bar.foo)
  end

  def test_has_accessible_state
    assert_respond_to @dbc_object, :state
    assert_respond_to @dbc_object, :state=
  end
end
