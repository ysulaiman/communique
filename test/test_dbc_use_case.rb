require_relative 'test_helpers'

class TestDbcUseCase < MiniTest::Unit::TestCase
  def setup
    @use_case = DbcUseCase.new('a_use_case')
    @dbc_object = DbcObject.new('account_instance', :Account, {:@number => 42})
  end

  def test_has_name
    assert_equal 'a_use_case', @use_case.name
  end

  def test_has_accessible_dbc_instances
    assert_respond_to @use_case, :dbc_instances
    assert_respond_to @use_case, :dbc_instances=
  end

  def test_can_reset_its_dbc_instances
    @use_case.dbc_instances << @dbc_object
    @dbc_object.number = 666
    @use_case.reset_dbc_instances

    assert_equal 42, @use_case.dbc_instances.first.number
  end

  def test_has_accessible_postcondition
    assert_respond_to @use_case, :postconditions
    assert_respond_to @use_case, :postconditions=
  end
end
