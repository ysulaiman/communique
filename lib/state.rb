require 'ostruct'

class State < OpenStruct
  def initialize(name)
    super({name: name})
  end

  def satisfy?(condition)
    condition.call
  end
end
