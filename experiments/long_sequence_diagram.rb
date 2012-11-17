# The purpose of this experiment is to show that the planner is capable of
# finding a solution sequence diagram even if it is a long one.

require_relative 'experiment_helpers'

start_point = 1
end_point = 20

dbc_instance_variables = {}
(start_point..end_point).each do |i|
  dbc_instance_variables["@is_m#{i}_called".to_sym] = false
end

dbc_object = DbcObject.new('dbc_object', :A, dbc_instance_variables)

(start_point..end_point).each do |i|
  method = DbcMethod.new("m#{i}".to_sym)
  method.precondition = if i == start_point
                          Proc.new { true }
                        else
                          Proc.new do
                            instance_variable_get("@is_m#{i-1}_called")
                          end
                        end
  method.postcondition =
    Proc.new { instance_variable_set("@is_m#{i}_called", true) }

  dbc_object.add_dbc_methods(method)
end

# TODO: Add noise?

planner = Planner.new
planner.initial_state.add(dbc_object)
planner.goals = {
  'dbc_object' => Proc.new { instance_variable_get("@is_m#{end_point}_called") }
}
planner.algorithm = :best_first_forward_search

planner.solve
puts planner.plan
puts "# Goal Tests: #{planner.number_of_states_tested_for_goals}"
