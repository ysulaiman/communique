require_relative 'test_helpers'

class TestNoiseGenerator < MiniTest::Unit::TestCase
  def setup
    @number_of_methods = 5
    @dbc_methods = NoiseGenerator.generate_dbc_methods(@number_of_methods)
  end

  def test_generates_an_array_of_n_dbc_methods
    assert_equal @number_of_methods, @dbc_methods.size
    @dbc_methods.each { |m| assert m.is_a? DbcMethod }
  end

  def test_generates_dbc_methods_with_unique_names
    @dbc_methods.each { |m| assert @dbc_methods.one? { |n| m.name == n.name } }
  end

  def test_generates_dbc_methods_that_are_always_applicable
    @dbc_methods.each { |m| assert_equal true, m.precondition.call }
  end

  def test_generates_dbc_methods_that_does_not_modify_their_receivers
    receiver_before_applying_postcondition = DbcObject.new('foo', :Foo, {
      :@foo => 'foo'
    })
    receiver_before_applying_postcondition.add_dbc_methods(*@dbc_methods)

    receiver_after_applying_postcondition =
      receiver_before_applying_postcondition.clone

    @dbc_methods.each do |method|
      receiver_after_applying_postcondition.apply(&method.postcondition)

      assert_equal receiver_before_applying_postcondition,
                   receiver_after_applying_postcondition
    end
  end
end
