require 'benchmark'

require_relative '../lib/dbc_method'
require_relative '../lib/dbc_object'
require_relative '../lib/dbc_use_case'
require_relative '../lib/noise_generator'
require_relative '../lib/planner'

def solve_and_report(use_case)
  planner = Planner.new(:best_first_forward_search)
  planner.set_up_initial_state(use_case)
  planner.goals = use_case.postconditions

  puts "Solving UC #{use_case.name} ..."
  planner.solve
  puts "Solution: #{planner.plan}"
  puts "# Goal Tests: #{planner.number_of_states_tested_for_goals}\n\n"
end
