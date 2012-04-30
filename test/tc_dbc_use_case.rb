require_relative '../lib/dbc_use_case'
require 'minitest/autorun'

class TestDbcUseCase < MiniTest::Unit::TestCase
  def setup
    @use_case = DbcUseCase.new('a_use_case')
  end

  def test_has_name
    assert_equal 'a_use_case', @use_case.name
  end

  def test_has_precondition
    assert_respond_to @use_case, :precondition
    assert_respond_to @use_case, :precondition=
  end

  def test_has_postcondition
    assert_respond_to @use_case, :postcondition
    assert_respond_to @use_case, :postcondition=
  end
end
