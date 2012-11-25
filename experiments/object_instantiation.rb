# The purpose of this experiment is to show that the planner is capable of
# generating a sequence diagram that involves object instantiation.

require_relative 'experiment_helpers'


sd_postprocessor = DbcObject.new('sd_postprocessor', :SequenceDiagramPostprocessor, {
  :@is_sequence_diagram_postprocessed => false
})

sd_generator = DbcObject.new('sd_generator', :SequenceDiagramGenerator, {
  :@is_use_case_model_read => false,
  :@is_class_model_read => false,
  :@is_sequence_diagram_generated => false,
  :@sd_postprocessor => sd_postprocessor
})

planner = DbcObject.new('planner', :Planner, {
  :@is_problem_set_up => false,
  :@is_plan_generated => false
})
# planner is a dependency object of the `generate()` method of
# SequenceDiagramGenerator.
planner.dead = true


# SequenceDiagramPostprocessor methods.
postprocess = DbcMethod.new(:postprocess)
postprocess.precondition = Proc.new do
  state.get_instance_named('planner').is_plan_generated
end
postprocess.postcondition = Proc.new do
  @is_sequence_diagram_postprocessed = true
end

sd_postprocessor.add_dbc_methods(postprocess)


# SequenceDiagramGenerator methods.
read_use_case_model = DbcMethod.new(:read_use_case_model)
read_use_case_model.precondition = Proc.new { true }
read_use_case_model.postcondition = Proc.new do
  @is_use_case_model_read = true
end

read_class_model = DbcMethod.new(:read_class_model)
read_class_model.precondition = Proc.new { true }
read_class_model.postcondition = Proc.new do
  @is_class_model_read = true
end

generate = DbcMethod.new(:generate)
generate.precondition = Proc.new do
  @is_use_case_model_read && @is_class_model_read
end
generate.postcondition = Proc.new do
  @is_sequence_diagram_generated = true
end
generate.dependencies.push(planner.dbc_name)

sd_generator.add_dbc_methods(read_use_case_model, read_class_model, generate)


# Planner methods.
set_up_problem = DbcMethod.new(:set_up_problem)
set_up_problem.precondition = Proc.new do
  state.get_instance_named('sd_generator').is_use_case_model_read &&
    state.get_instance_named('sd_generator').is_class_model_read
end
set_up_problem.postcondition = Proc.new do
  @is_problem_set_up = true
end

solve = DbcMethod.new(:solve)
solve.precondition = Proc.new do
  @is_problem_set_up
end
solve.postcondition = Proc.new do
  @is_plan_generated = true
end

planner.add_dbc_methods(set_up_problem, solve)


metaplanner = Planner.new(:best_first_forward_search)
metaplanner.initial_state.add(sd_postprocessor, sd_generator, planner)
metaplanner.goals = {
  'sd_generator' => Proc.new { @is_sequence_diagram_generated },
  'sd_postprocessor' => Proc.new { @is_sequence_diagram_postprocessed }
}

metaplanner.solve

puts prettify_plan(metaplanner.plan, %w(Caller Method Receiver))
puts "# Goal Tests: #{metaplanner.number_of_states_tested_for_goals}"

if metaplanner.plan == :failure
  puts "Failed to satisfy the goals of the following objects:"
  puts metaplanner.unsatisfied_objects_names
end
