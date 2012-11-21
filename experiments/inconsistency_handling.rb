# The purpose of this experiment is to show that the planner is capable of
# pointing out possible inconsistencies that caused it to fail in finding a
# sequence diagram.

require_relative 'experiment_helpers'

sequence_diagram_generator = DbcObject.new('sequence_diagram_generator',
                                           :SequenceDiagramGenerator,
                                           {:@is_diagram_saved => false})

planner = DbcObject.new('planner', :Planner, {:@is_done_solving => false})
planner.dead = true

generate = DbcMethod.new(:generate)
generate.precondition = Proc.new { true }
generate.postcondition = Proc.new {}
generate.dependencies.push(planner.dbc_name)
sequence_diagram_generator.add_dbc_methods(generate)

# Intentionally introduce an inconsistency by not adding a
# `SequenceDiagramGenerator#save_diagram()` method.

solve = DbcMethod.new(:solve)
solve.precondition = Proc.new { true }
solve.postcondition = Proc.new { @is_done_solving = true }
planner.add_dbc_methods(solve)

metaplanner = Planner.new(:best_first_forward_search)
metaplanner.initial_state.add(sequence_diagram_generator, planner)
metaplanner.goals = {
  'sequence_diagram_generator' => Proc.new { @is_diagram_saved },
  'planner' => Proc.new { @is_done_solving }
}

metaplanner.solve

if metaplanner.plan == :failure
  puts "Failed to satisfy the goals of the following objects:"
  puts metaplanner.unsatisfied_objects_names
end
