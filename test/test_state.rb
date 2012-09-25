require_relative 'test_helpers'

class TestState < MiniTest::Unit::TestCase
  def setup
    account_instance = DbcObject.new('account_instance', :Account, {
      :@number => 42,
      :@holder => 'John Doe'
    })
    @state = State.new('S0', [account_instance])
  end

  def test_has_name
    assert_equal 'S0', @state.name
  end

  def test_can_add_dbc_object_to_itself
    foo_instance = DbcObject.new('foo_instance', :Foo, { :@bar => 'bar' })
    @state.add(foo_instance)

    assert_equal true, @state.include_instance_of?(:Foo)
  end

  def test_can_add_multiple_dbc_object_to_itself_in_one_call
    foo = DbcObject.new('foo', :Foo, {})
    bar = DbcObject.new('bar', :Bar, {})
    baz = DbcObject.new('baz', :Baz, {})
    @state.add(foo, bar, baz)

    assert @state.include_instance_of?(:Foo) &&
      @state.include_instance_of?(:Bar) &&
      @state.include_instance_of?(:Baz)
  end

  def test_can_check_if_it_satisfies_conditions
    assert_equal true, @state.satisfy? { @number == 42 }
  end

  def test_can_apply_postconditions_to_one_of_its_dbc_objects
    @state.apply('account_instance') do
      @number = 666
      @holder = 'Jane Doe'
    end

    assert_equal true, @state.satisfy? { @number == 666 && @holder == 'Jane Doe' }
  end

  def test_can_check_if_it_contains_an_instance_of_a_DbC_class
    assert_equal true, @state.include_instance_of?(:Account)
  end

  def test_responds_to_get_dbc_methods_of_instances
    assert_respond_to @state, :get_dbc_methods_of_instances
  end

  def test_clones_its_dbc_objects_in_the_process_of_cloning_itself
    new_state = @state.clone

    assert new_state.include_instance_of?(:Account)
  end

  def test_copies_its_current_dbc_objects
    @state.apply('account_instance') do
      @number = 666
      @holder = 'Jane Doe'
    end
    new_state = @state.clone

    assert new_state.satisfy? { @number == 666 && @holder == 'Jane Doe' }
  end

  def test_applying_postconditions_to_it_does_not_affect_its_copies
    unaffected_state = @state.clone
    @state.apply('account_instance') do
      @number = 666
      @holder = 'Jane Doe'
    end

    assert unaffected_state.satisfy? { @number == 42 && @holder == 'John Doe' }
  end
end
