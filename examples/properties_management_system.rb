# This is a (quick and dirty) example script that uses the library's classes to
# plan and generate a number of sequence diagrams (albeit in textual format).
# The example classes and use cases are taken (with some modifications) from a
# senior project about a Properties Management System.

require_relative '../lib/dbc_method'
require_relative '../lib/dbc_object'
require_relative '../lib/dbc_use_case'
require_relative '../lib/planner'


account_instance = DbcObject.new('account', :Account, {
  :@is_logged_in => false
})

# TODO: Use login parameters (username and password).
log_in = DbcMethod.new('log_in')
log_in.precondition = Proc.new do
  @dbc_class == :Account &&
    !@is_logged_in
end
log_in.postcondition = Proc.new { @is_logged_in = true }

log_out = DbcMethod.new('log_out')
log_out.precondition = Proc.new do
  @dbc_class == :Account &&
    @is_logged_in
end
log_out.postcondition = Proc.new { @is_logged_in = false }

account_instance.add_dbc_methods(log_in, log_out)


property_instance = DbcObject.new('property', :Property, {
  :@account => account_instance,
  :@properties_are_listed => false,
  :@is_modified => false,
  :@manager_is_notified => false,
  :@is_featured => false,
  :@deleted => false,
  :@is_added => false
})

show_properties = DbcMethod.new('show_properties')
show_properties.precondition = Proc.new do
  @dbc_class == :Property &&
    @account.is_logged_in &&
    !@deleted
end
show_properties.postcondition = Proc.new { @properties_are_listed = true }

modify_property = DbcMethod.new('modify_property')
modify_property.precondition = Proc.new do
  @dbc_class == :Property &&
    @account.is_logged_in &&
    @properties_are_listed &&
    !@deleted
end
modify_property.postcondition = Proc.new do
  @is_modified = true
  @manager_is_notified = true
end

select_featured_property = DbcMethod.new('select_featured_property')
select_featured_property.precondition = Proc.new do
  @dbc_class == :Property &&
    @account.is_logged_in &&
    !@is_featured &&
    !@deleted
end
select_featured_property.postcondition = Proc.new { @is_featured = true }

unselect_featured_property = DbcMethod.new('unselect_featured_property')
unselect_featured_property.precondition = Proc.new do
  @dbc_class == :Property &&
    @account.is_logged_in &&
    @is_featured &&
    !@deleted
end
unselect_featured_property.postcondition = Proc.new { @is_featured = false }

delete_property = DbcMethod.new('delete_property')
delete_property.precondition = Proc.new do
  @dbc_class == :Property &&
    @account.is_logged_in &&
    @properties_are_listed &&
    !@deleted
end
delete_property.postcondition = Proc.new do
  @deleted = true
  @manager_is_notified = true
end

add_property = DbcMethod.new('add_property')
add_property.precondition = Proc.new do
  @dbc_class == :Property &&
    @account.is_logged_in
end
# TODO: Real postcondition for adding a property?
add_property.postcondition = Proc.new do
  @is_added = true
  @manager_is_notified = true
end

property_instance.add_dbc_methods(show_properties, modify_property, select_featured_property, unselect_featured_property, delete_property, add_property)


announcement_instance = DbcObject.new('announcement', :Announcement, {
  :@account => account_instance,
  :@announcements_are_listed => false,
  :@is_modified => false,
  :@manager_is_notified => false,
})

show_announcements = DbcMethod.new('show_announcements')
show_announcements.precondition = Proc.new do
  @dbc_class == :Announcement &&
    @account.is_logged_in
end
show_announcements.postcondition = Proc.new { @announcements_are_listed = true }

modify_announcement = DbcMethod.new('modify_announcement')
modify_announcement.precondition = Proc.new do
  @dbc_class == :Announcement &&
    @account.is_logged_in &&
    @announcements_are_listed
end
modify_announcement.postcondition = Proc.new do
  @is_modified = true
  @manager_is_notified = true
end

announcement_instance.add_dbc_methods(show_announcements, modify_announcement)


login_use_case = DbcUseCase.new('Login')
login_use_case.dbc_instances << account_instance
login_use_case.postconditions = {'account' => Proc.new { @is_logged_in }}

planner = Planner.new(:recursive_forward_search)
planner.initial_state.add(account_instance, property_instance)
planner.goals = login_use_case.postconditions

puts "Solving UC #{login_use_case.name} ..."
planner.solve
puts "Solution: #{planner.plan}\n\n"


modify_property_use_case = DbcUseCase.new('Modify Property')
modify_property_use_case.dbc_instances << account_instance << property_instance
modify_property_use_case.reset_dbc_instances
account_instance.is_logged_in = true
modify_property_use_case.postconditions = {'property' => Proc.new { @is_modified && @manager_is_notified }}

planner = Planner.new(:recursive_forward_search)
planner.set_up_initial_state(modify_property_use_case)
planner.goals = modify_property_use_case.postconditions

puts "Solving UC #{modify_property_use_case.name} ..."
planner.solve
puts "Solution: #{planner.plan}\n\n"


select_featured_property_use_case = DbcUseCase.new('Select Featured Property')
select_featured_property_use_case.dbc_instances << account_instance << property_instance
modify_property_use_case.reset_dbc_instances
account_instance.is_logged_in = true
select_featured_property_use_case.postconditions = {'property' => Proc.new { @is_featured }}

planner = Planner.new(:recursive_forward_search)
planner.set_up_initial_state(select_featured_property_use_case)
planner.goals = select_featured_property_use_case.postconditions

puts "Solving UC #{select_featured_property_use_case.name} ..."
planner.solve
puts "Solution: #{planner.plan}\n\n"


delete_property_use_case = DbcUseCase.new('Delete Property')
delete_property_use_case.dbc_instances << account_instance << property_instance
delete_property_use_case.reset_dbc_instances
account_instance.is_logged_in = true
delete_property_use_case.postconditions = {'property' => Proc.new { @deleted && @manager_is_notified }}

planner = Planner.new(:recursive_forward_search)
planner.set_up_initial_state(delete_property_use_case)
planner.goals = delete_property_use_case.postconditions

puts "Solving UC #{delete_property_use_case.name} ..."
planner.solve
puts "Solution: #{planner.plan}\n\n"


add_property_use_case = DbcUseCase.new('Add Property')
add_property_use_case.dbc_instances << account_instance << property_instance
add_property_use_case.reset_dbc_instances
account_instance.is_logged_in = true
add_property_use_case.postconditions = {'property' => Proc.new { @is_added && @manager_is_notified }}

planner = Planner.new(:recursive_forward_search)
planner.set_up_initial_state(add_property_use_case)
planner.goals = add_property_use_case.postconditions

puts "Solving UC #{add_property_use_case.name} ..."
planner.solve
puts "Solution: #{planner.plan}\n\n"


modify_announcement_use_case = DbcUseCase.new('Modify Announcement')
modify_announcement_use_case.dbc_instances << account_instance << property_instance << announcement_instance
modify_announcement_use_case.reset_dbc_instances
account_instance.is_logged_in = true
modify_announcement_use_case.postconditions = {'announcement' => Proc.new { @is_modified && @manager_is_notified }}

planner = Planner.new(:recursive_forward_search)
planner.set_up_initial_state(modify_announcement_use_case)
planner.goals = modify_announcement_use_case.postconditions

puts "Solving UC #{modify_announcement_use_case.name} ..."
planner.solve
puts "Solution: #{planner.plan}\n\n"
