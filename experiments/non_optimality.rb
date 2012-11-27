# The purpose of this (contrived) experiment is to highlight a limitation of
# the planner: it is not an optimal one. The non-optimality is due to the used
# non-admissible heuristic, which is the number of objects not satisfying their
# conditions.
#
# The optimal sequence diagram consists of 2 methods calls:
# `prepare_to_satisfy_all_objects_at_once` followed by
# `satisfy_all_objects_at_once`. Instead, the planner generates a non-optimal
# sequence diagram that consists of the other 3 method calls:
# `satisfy_objects_1_and_2`, `prepare_to_satisfy_object_3`, and
# `satisfy_object_3`.

require_relative 'experiment_helpers'


object_1 = DbcObject.new('object_1', :Object, {
  :@is_satisfied => false
})

object_2 = DbcObject.new('object_2', :Object, {
  :@is_satisfied => false
})

object_3 = DbcObject.new('object_3', :Object, {
  :@is_satisfied => false
})

controller = DbcObject.new('controller', :Controller, {
  :@is_prepared_to_satisfy_all_objects_at_once => false,
  :@is_prepared_to_satisfy_object_3 => false,
  :@object_1 => object_1,
  :@object_2 => object_2,
  :@object_3 => object_3,
})


prepare_to_satisfy_all_objects_at_once =
  DbcMethod.new(:prepare_to_satisfy_all_objects_at_once)
prepare_to_satisfy_all_objects_at_once.precondition = Proc.new do
  !@object_1.is_satisfied && !@object_2.is_satisfied && !@object_3.is_satisfied
end
prepare_to_satisfy_all_objects_at_once.postcondition = Proc.new do
  @is_prepared_to_satisfy_all_objects_at_once = true
end

satisfy_all_objects_at_once = DbcMethod.new(:satisfy_all_objects_at_once)
satisfy_all_objects_at_once.precondition = Proc.new do
  @is_prepared_to_satisfy_all_objects_at_once
end
satisfy_all_objects_at_once.postcondition = Proc.new do
  @object_1.is_satisfied = @object_2.is_satisfied = @object_3.is_satisfied =
    true
end

satisfy_objects_1_and_2 = DbcMethod.new(:satisfy_objects_1_and_2)
satisfy_objects_1_and_2.precondition = Proc.new do
  !@object_1.is_satisfied && !@object_2.is_satisfied
end
satisfy_objects_1_and_2.postcondition = Proc.new do
  @object_1.is_satisfied = @object_2.is_satisfied = true
end

prepare_to_satisfy_object_3 = DbcMethod.new(:prepare_to_satisfy_object_3)
prepare_to_satisfy_object_3.precondition = Proc.new do
  @object_1.is_satisfied && @object_2.is_satisfied &&
    !@object_3.is_satisfied && !@is_prepared_to_satisfy_object_3
end
prepare_to_satisfy_object_3.postcondition = Proc.new do
  @is_prepared_to_satisfy_object_3 = true
end

satisfy_object_3 = DbcMethod.new(:satisfy_object_3)
satisfy_object_3.precondition = Proc.new { @is_prepared_to_satisfy_object_3 }
satisfy_object_3.postcondition = Proc.new do
  @object_3.is_satisfied = true
end

controller.add_dbc_methods(prepare_to_satisfy_all_objects_at_once,
                           satisfy_all_objects_at_once,
                           satisfy_objects_1_and_2,
                           prepare_to_satisfy_object_3,
                           satisfy_object_3)


planner = Planner.new(:best_first_forward_search)
planner.initial_state.add(controller, object_1, object_2, object_3)
planner.goals = {
  'object_1' => Proc.new { @is_satisfied },
  'object_2' => Proc.new { @is_satisfied },
  'object_3' => Proc.new { @is_satisfied },
}

planner.solve

puts prettify_plan(planner.plan, %w(Caller Method Receiver))
puts "# Goal Tests: #{planner.number_of_states_tested_for_goals}"

if planner.plan == :failure
  puts "Failed to satisfy the goals of the following objects:"
  puts planner.unsatisfied_objects_names
end
