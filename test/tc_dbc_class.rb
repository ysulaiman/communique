require_relative '../lib/dbc_class'
require 'minitest/autorun'

class TestDbcClass < MiniTest::Unit::TestCase
  def setup
    @dbc_class = DbcClass.new('AClass')
  end

  def test_has_name
    assert_equal 'AClass', @dbc_class.name
  end

  def test_has_attributes
    assert_respond_to @dbc_class, :attributes
    assert_respond_to @dbc_class, :attributes=
  end

  def test_initially_has_empty_attributes_list
    assert @dbc_class.attributes.empty?
  end

  def test_has_dbc_methods
    assert_respond_to @dbc_class, :dbc_methods
    assert_respond_to @dbc_class, :dbc_methods=
  end

  def test_initially_has_empty_dbc_methods_list
    assert @dbc_class.dbc_methods.empty?
  end

  def test_has_invariant
    assert_respond_to @dbc_class, :invariant
    assert_respond_to @dbc_class, :invariant=
  end
end
