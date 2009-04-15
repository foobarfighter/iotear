class SelectorStrategy
  attr_reader :enumerable, :current_index

  def initialize(enumerable)
    @enumerable = enumerable
    @current_index = 0
  end

  def tick
    if @current_index < @enumerable.size - 1
      @current_index += 1
      return @current_index
    else
      @current_index = 0
    end
    nil
  end

  def increment
    tick
    @current_index
  end
end