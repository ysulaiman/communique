require_relative 'dbc_method'

class NoiseGenerator
  def self.generate_dbc_methods(number_of_methods = 1)
    methods = []

    number_of_methods.times do |n|
      method = DbcMethod.new("method_#{n}")
      method.precondition = Proc.new { true }
      method.postcondition = Proc.new { }

      methods << method
    end

    methods
  end
end
