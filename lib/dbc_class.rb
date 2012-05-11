class DbcClass
  attr_accessor :name, :attributes, :dbc_methods, :invariant

  def initialize(name)
    @name = name
    @attributes = []
    @dbc_methods = []
  end
end
