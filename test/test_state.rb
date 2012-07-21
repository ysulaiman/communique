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
end
