module IOTear
  class Selector
    attr_reader :enumerable, :current_index

    def initialize(enumerable)
      raise ArgumentError unless enumerable.is_a?(Enumerable)
      @enumerable = enumerable
      @current_index = -1
    end

    def current
      @current_index == -1 ? @enumerable[0] : @enumerable[@current_index]
    end

    def get
      if @current_index < @enumerable.size - 1
        @current_index += 1
      else
        @current_index = 0
      end

      current
    end

    def find(&block)
      found = false
      begin
        found = yield(get)
      end while !found && !last?
      found ? current : nil
    end

    def last?
      @current_index == @enumerable.size - 1
    end
  end
end