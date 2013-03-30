# The purpose of this experiment is to study the relation between the number of
# methods that do not contribute to solving the problem at hand and the
# performance of the planner in terms of the number of explored nodes and the
# (execution) time taken by the planner to solve the problem.
#
# The use case and classes/objects used in this experiment are taken from the
# MeetingsMate senior project by Iyad Al Akel, Abdurrahman Al Kalaji, Loai
# Labani, Fahad Al Hazemi, Aseel Ba Haziq, and Hani Al Zahrani.

require_relative 'experiment_helpers'

notification_instance = DbcObject.new('notification', :Notification, {
  :@meeting => nil,
  :@user_profile => nil
})

vote_instance = DbcObject.new('vote', :Vote, {
  :@is_closed => false
})

meeting_instance = DbcObject.new('meeting', :Meeting, {
  :@is_final_meeting_time_set => false,
  :@is_final_meeting_location_set => false,
  :@vote => vote_instance,
  :@notification => notification_instance
})

user_profile_instance = DbcObject.new('user_profile', :UserProfile, {
  :@is_logged_in => true,
  :@notifications => [],
  :@meeting => meeting_instance
})

update_user_notifications = DbcMethod.new(:update_user_notifications)
update_user_notifications.precondition = Proc.new do
  state.get_instance_of(:Notification).meeting &&
    @meeting.is_final_meeting_time_set &&
    @meeting.is_final_meeting_location_set
end
update_user_notifications.postcondition = Proc.new do
  @notifications << state.get_instance_of(:Notification)
end

user_profile_instance.add_dbc_methods(update_user_notifications)

add_notification = DbcMethod.new(:add_notification)
add_notification.precondition = Proc.new do
  state.get_instance_of(:Meeting) &&
    state.get_instance_of(:Meeting).vote.is_closed
end
add_notification.postcondition = Proc.new do
  @meeting = state.get_instance_of(:Meeting)
  @user_profile = state.get_instance_of(:UserProfile)
end

notification_instance.add_dbc_methods(add_notification)

close_vote = DbcMethod.new(:close_vote)
close_vote.precondition = Proc.new do
  ! @is_closed &&
    state.get_instance_of(:Meeting).is_final_meeting_time_set &&
    state.get_instance_of(:Meeting).is_final_meeting_location_set
end
close_vote.postcondition = Proc.new { @is_closed = true }

vote_instance.add_dbc_methods(close_vote)

set_final_meeting_location = DbcMethod.new(:set_final_meeting_location)
set_final_meeting_location.precondition = Proc.new { @is_final_meeting_time_set }
set_final_meeting_location.postcondition = Proc.new do
  @is_final_meeting_location_set = true
end

set_final_meeting_time = DbcMethod.new(:set_final_meeting_time)
set_final_meeting_time.precondition = Proc.new { true }
set_final_meeting_time.postcondition = Proc.new do
  @is_final_meeting_time_set = true
end

meeting_instance.add_dbc_methods(set_final_meeting_location,
                                 set_final_meeting_time)

finalize_meeting_use_case = DbcUseCase.new('Finalize Meeting')
finalize_meeting_use_case.dbc_instances << notification_instance <<
  vote_instance << meeting_instance << user_profile_instance
finalize_meeting_use_case.postconditions = {
  'meeting' => Proc.new { @is_final_meeting_time_set &&
    @is_final_meeting_location_set },
  'vote' => Proc.new { @is_closed },
  'notification' => Proc.new { ! @meeting.nil? },
  'user_profile' => Proc.new { @notifications.include? state.get_instance_named('notification') }
}

ALGORITHM = :best_first_forward_search
puts "Using #{ALGORITHM}"

File.open("#{Time.now.to_i}_#{ALGORITHM}", "w") do |file|
  header = %w( NoiseMethods UserTime SystemTime ChildrenUserTime ChildrenSystemTime RealTime GoalTests PlanLength )
  file.puts header.join(',')

  (0..10).each do |number_of_noise_methods|
    print "#{number_of_noise_methods} Noise Methods:"

    dummy_dbc_instance = DbcObject.new('dummy_object', :DummyClass, {})

    noise_dbc_methods =
      NoiseGenerator.generate_dbc_methods(number_of_noise_methods)
    dummy_dbc_instance.add_dbc_methods(*noise_dbc_methods)

    finalize_meeting_use_case.dbc_instances.delete_at(0) unless
      number_of_noise_methods == 0
    finalize_meeting_use_case.dbc_instances.unshift(dummy_dbc_instance)

    planner = Planner.new
    planner.set_up_initial_state(finalize_meeting_use_case)
    planner.goals = finalize_meeting_use_case.postconditions
    planner.algorithm = ALGORITHM

    # Initialize the pseudo-random number generator that will be used in the
    # shuffling loop with a fixed seed to make the results reproducible and
    # to generate the same sequence of search spaces for the search algorithms.
    prng = Random.new(42)

    30.times do
      data_row = Benchmark.measure { planner.solve(random: prng) }.to_a

      data_row.delete_at(0)  # Remove the unneeded empty "label" element.
      data_row.unshift(number_of_noise_methods)
      data_row << planner.number_of_states_tested_for_goals << planner.plan.length

      file.puts data_row.join(',')

      print '.'
    end

    puts
  end
end
