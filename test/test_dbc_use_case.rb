require_relative 'test_helpers'

class TestDbcUseCase < MiniTest::Unit::TestCase
  def setup
    @use_case = DbcUseCase.new('a_use_case')
  end

  def test_has_name
    assert_equal 'a_use_case', @use_case.name
  end

  def test_has_accessible_percondition
    assert_respond_to @use_case, :precondition
    assert_respond_to @use_case, :precondition=
  end

  def test_has_accessible_postcondition
    assert_respond_to @use_case, :postcondition
    assert_respond_to @use_case, :postcondition=
  end
end
