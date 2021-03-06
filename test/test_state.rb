require_relative 'test_helpers'

class TestState < MiniTest::Unit::TestCase
  def setup
    @account_instance = DbcObject.new('account_instance', :Account, {
      :@number => 42,
      :@holder => 'John Doe'
    })
    @state = State.new('S0', [@account_instance])

    @foo_instance = DbcObject.new('foo_instance', :Foo, { :@foo => 'foo' })
  end

  def test_has_name
    assert_equal 'S0', @state.name
  end

  def test_can_add_dbc_object_to_itself
    @state.add(@foo_instance)

    assert_equal true, @state.include_instance_of?(:Foo)
  end

  def test_sets_state_of_dbc_object_when_it_gets_added
    assert_equal @state, @account_instance.state

    @state.add(@foo_instance)

    assert_equal @state, @foo_instance.state
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
    assert_equal true, @state.satisfy?({
      'account_instance' => Proc.new { @number == 42 }
    })

    assert_equal false, @state.satisfy?({
      'account_instance' => Proc.new { @number == 666 }
    })
  end

  def test_does_not_satisfy_conditions_of_its_dbc_objects_that_are_explicitly_marked_as_dead
    @account_instance.dead = true

    assert_equal false, @state.satisfy?({
      'account_instance' => Proc.new { @number == 42 }
    })
  end

  def test_can_be_asked_how_many_of_its_objects_do_not_satisfy_their_conditions
    @state.add(@foo_instance)

    assert_equal 0, @state.number_of_objects_not_satisfying_their_conditions({
      'account_instance' => Proc.new { @number == 42 },
      'foo_instance' => Proc.new { @foo == 'foo' }
    })

    assert_equal 1, @state.number_of_objects_not_satisfying_their_conditions({
      'account_instance' => Proc.new { @number == 666 }
    })

    assert_equal 2, @state.number_of_objects_not_satisfying_their_conditions({
      'account_instance' => Proc.new { @number == 666 },
      'foo_instance' => Proc.new { @foo == 'bar' },
    })
  end

  def test_can_report_names_of_its_dbc_objects_that_do_not_satisfy_their_conditions
    @state.add(@foo_instance)

    assert_equal [], @state.names_of_objects_not_satisfying_their_conditions({
      'account_instance' => Proc.new { @number == 42 },
      'foo_instance' => Proc.new { @foo == 'foo' }
    })

    assert_equal [@account_instance.dbc_name],
      @state.names_of_objects_not_satisfying_their_conditions({
        'account_instance' => Proc.new { @number == 666 },
        'foo_instance' => Proc.new { @foo == 'foo' }
      })

    assert_equal [@account_instance.dbc_name, @foo_instance.dbc_name],
      @state.names_of_objects_not_satisfying_their_conditions({
        'account_instance' => Proc.new { @number == 666 },
        'foo_instance' => Proc.new { @foo == 'bar' }
      })
  end

  def test_can_apply_postconditions_to_one_of_its_dbc_objects
    @state.apply('account_instance') do
      @number = 666
      @holder = 'Jane Doe'
    end

    assert_equal true, @state.satisfy?({
      'account_instance' => Proc.new { @number == 666 && @holder == 'Jane Doe' }
    })
  end

  def test_responds_to_get_dbc_methods_of_instances
    assert_respond_to @state, :get_dbc_methods_of_instances
  end

  def test_clones_its_dbc_objects_in_the_process_of_cloning_itself
    new_state = @state.clone

    assert new_state.include_instance_of?(:Account)
  end

  def test_knows_if_it_contains_a_dbc_object_of_a_given_dbc_class
    assert_equal true, @state.include_instance_of?(:Account)
  end

  def test_knows_if_it_contains_a_dbc_object_with_a_given_name
    assert_equal true, @state.include_instance_named?('account_instance')
  end

  def test_can_return_one_of_its_dbc_objects_given_its_dbc_class
    assert_equal @account_instance, @state.get_instance_of(:Account)
  end

  def test_can_return_one_of_its_dbc_objects_given_its_dbc_name
    assert_equal @account_instance,
                 @state.get_instance_named('account_instance')
  end

  def test_should_not_create_more_than_one_clone_of_each_of_its_dbc_objects
    host = DbcObject.new('host', :Vote, {})
    first_meeting = DbcObject.new('first_meeting', :Meeting, {
      :@host => host
    })
    second_meeting = DbcObject.new('second_meeting', :Meeting, {
      :@host => host
    })
    state = State.new('state', [host, first_meeting, second_meeting])

    new_state = state.clone
    new_host = new_state.get_instance_named('host')
    new_first_meeting = new_state.get_instance_named('first_meeting')
    new_second_meeting = new_state.get_instance_named('second_meeting')

    assert new_host.equal?(new_first_meeting.host)
    assert new_host.equal?(new_second_meeting.host)
    assert new_host.equal?(new_state.get_instance_of(:Meeting).host)
  end

  def test_correctly_clones_its_dbc_objects_that_have_circular_references
    display = DbcObject.new('display', :Display, {
      :@watch => nil
    })
    time = DbcObject.new('time', :Time, {
      :@watch => nil
    })
    watch = DbcObject.new('watch', :Watch, {
      :@display => display,
      :@time => time
    })
    display.watch = watch
    time.watch = watch

    state = State.new('state', [display, time, watch])

    new_state = state.clone
    new_watch = new_state.get_instance_named('watch')
    new_display = new_state.get_instance_named('display')
    new_time = new_state.get_instance_named('time')

    assert new_display.equal?(new_watch.display)
    assert new_time.equal?(new_watch.time)

    assert new_watch.equal?(new_display.watch)
    assert new_watch.equal?(new_time.watch)
    assert new_watch.equal?(new_state.get_instance_of(:Display).watch)
    assert new_watch.equal?(new_state.get_instance_of(:Time).watch)
  end

  def test_copies_its_current_dbc_objects
    @state.apply('account_instance') do
      @number = 666
      @holder = 'Jane Doe'
    end
    new_state = @state.clone

    assert new_state.satisfy?({
      'account_instance' => Proc.new { @number == 666 && @holder == 'Jane Doe' }
    })
  end

  def test_applying_postconditions_to_it_does_not_affect_its_copies
    unaffected_state = @state.clone
    @state.apply('account_instance') do
      @number = 666
      @holder = 'Jane Doe'
    end

    assert unaffected_state.satisfy?({
      'account_instance' => Proc.new { @number == 42 && @holder == 'John Doe' }
    })
  end

  def test_can_determine_which_of_its_dbc_objects_refer_to_object_given_its_name
    door_instance = DbcObject.new('door', :Door, {:@is_open => false})
    correct_room_instance = DbcObject.new('incorrect_room', :Room, {
      :@door => door_instance
    })
    incorrect_room_instance = DbcObject.new('correct_room', :Room, {
      :@door => nil
    })

    @state.add(door_instance, correct_room_instance, incorrect_room_instance)

    assert_equal [], @state.dbc_objects_refering_to('nonexisting_object')

    assert_equal [correct_room_instance],
                 @state.dbc_objects_refering_to('door')
  end

  def test_equals_another_state_if_they_are_both_empty
    empty_state_1 = State.new(:s1, [])
    empty_state_2 = State.new(:s2, [])

    assert_equal empty_state_1, empty_state_2
  end

  def test_does_not_equal_another_state_if_only_one_is_empty
    empty_state = State.new(:s1, [])

    refute_equal @state, empty_state
  end

  def test_equals_another_state_if_they_contain_equal_dbc_objects
    state_1 = State.new(:s1, [DbcObject.new(:foo, :Foo, {:@foo => :foo})])
    state_2 = State.new(:s2, [DbcObject.new(:foo, :Foo, {:@foo => :foo})])

    assert_equal state_1, state_2
  end

  def test_does_not_equal_another_state_if_they_contain_unequal_dbc_objects
    state = State.new(:s1, [DbcObject.new(:foo, :Foo, {:@foo => :foo})])
    state_with_different_dbc_object_name =
      State.new(:s2, [DbcObject.new(:bar, :Foo, {:@foo => :foo})])
    state_with_different_dbc_instance_variable_name =
      State.new(:s3, [DbcObject.new(:foo, :Foo, {:@bar => :foo})])
    state_with_different_dbc_instance_variable_value =
      State.new(:s4, [DbcObject.new(:foo, :Foo, {:@foo => :bar})])

    refute_equal state, state_with_different_dbc_object_name
    refute_equal state, state_with_different_dbc_instance_variable_name
    refute_equal state, state_with_different_dbc_instance_variable_value
  end

  def test_can_handle_circular_references_when_testing_for_equality
    foo1 = DbcObject.new(:foo, :Foo, {:@bar => nil})
    bar1 = DbcObject.new(:bar, :Bar, {:@foo => nil})
    foo1.bar = bar1
    bar1.foo = foo1
    state_1 = State.new(:state_1, [foo1, bar1])

    foo2 = DbcObject.new(:foo, :Foo, {:@bar => nil})
    bar2 = DbcObject.new(:bar, :Bar, {:@foo => nil})
    foo2.bar = bar2
    bar2.foo = foo2
    state_2 = State.new(:state_2, [foo2, bar2])

    assert_equal state_1, state_2
  end
end
