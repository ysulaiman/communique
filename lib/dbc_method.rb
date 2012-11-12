class DbcMethod
  attr_accessor :name, :parameters, :precondition, :postcondition,
    :receiver_name, :dependencies

  alias_method :effect, :postcondition
  alias_method :effect=, :postcondition=

  def initialize(name, parameters={}, dependencies=[])
    @name = name
    @parameters = parameters
    @dependencies = dependencies
  end

  def ==(other)
    return true if other.equal?(self)
    return false unless other.instance_of?(self.class)

    other.name == @name && other.parameters == @parameters &&
      other.receiver_name == @receiver_name
    # TODO: You may also need to compare preconditions and postconditions.
    # Since they are Procs, the Sourcify gem should come in handy.
  end
end
