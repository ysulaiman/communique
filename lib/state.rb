require 'ostruct'

class State < OpenStruct
  def initialize(name)
    super({name: name})
  end

  def apply(&effect)
    instance_eval &effect
  end

  def satisfy?(&condition)
    instance_eval &condition
  end
end
