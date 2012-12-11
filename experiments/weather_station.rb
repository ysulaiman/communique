# The purpose of this experiment is to show that the planner is capable of
# generating a sequence diagram similar to one in a software engineering book.
# The sequence diagram in question is the one for the weather station system
# depicted in Figure 14.13 of Software Engineering by Ian Sommerville. Some of
# the relevant classes are depicted in Figure 14.11.

require_relative 'experiment_helpers'


weather_data = DbcObject.new('weather_data', :WeatherData, {
  # TODO: instance variables from Figure 14.11
  :@is_data_summarised => false
})

comms_controller = DbcObject.new('comms_controller', :CommsController, {
  :@is_request_received => false,
  :@is_report_sent => false,
  :@weather_station => nil
})

weather_station = DbcObject.new('weather_station', :WeatherStation, {
  :@identifier => :ws1,
  :@is_report_ready => false,
  :@comms_controller => comms_controller,
  :@weather_data => weather_data
})

comms_controller.weather_station = weather_station


# WeatherData methods
summarise = DbcMethod.new(:summarise)
summarise.precondition = Proc.new { ! @is_data_summarised }
summarise.postcondition = Proc.new { @is_data_summarised = true }

weather_data.add_dbc_methods(summarise)


# CommsController methods
request = DbcMethod.new(:request)
request.parameters = {report: :r}
request.precondition = Proc.new { true }
request.postcondition = Proc.new { @is_request_received = true }

send = DbcMethod.new(:send)
send.parameters = {report: :r}
# TODO: The following precondition does not work. Why?
#send.precondition = Proc.new { @weather_station.weather_data.is_data_summarised }
send.precondition = Proc.new do
  state.get_instance_named('weather_data').is_data_summarised &&
    @weather_station.is_report_ready
end
send.postcondition = Proc.new { @is_report_sent = true }

comms_controller.add_dbc_methods(request, send)


# WeatherStation methods
report = DbcMethod.new(:report)
report.precondition = Proc.new { @comms_controller.is_request_received }
report.postcondition = Proc.new { @is_report_ready = true }

weather_station.add_dbc_methods(report)


planner = Planner.new(:best_first_forward_search)
planner.initial_state.add(comms_controller, weather_station, weather_data)
planner.goals = {
  'comms_controller' => Proc.new { @is_report_sent }
}

planner.solve
# TODO: prettify_plan(), which uses text-tables, does not work if some method
# calls in the plan contain parameters and others don't. Why?
pp planner.plan.map(&:values) unless planner.plan == :failure
puts "# Goal Tests: #{planner.number_of_states_tested_for_goals}"

if planner.plan == :failure
  puts "Failed to satisfy the goals of the following objects:"
  puts planner.unsatisfied_objects_names
end
