class TimelockEvent
  class Config
    LockerKeyNotDefined = Class.new(StandardError)
    RedisConnectionNotSpecified = Class.new(StandardError)

    attr_writer :lock_for, :unlock_hour_window,
      :current_time_parser, :current_time_evaluator,
      :current_time_str_generator, :key, :redis_connection

    def lock_for
      @lock_for ||= 24.hours
    end

    def unlock_hour_window
       @unlock_hour_window ||= 2..3
    end

    def current_time_evaluator
      @current_time_evaluator ||= ->{ Time.now }
    end

    def current_time_parser
      @current_time_parser ||= ->(time_str){ Time.parse(time_str) }
    end

    def current_time_str_generator
      @current_time_str_generator ||= ->{ current_time_evaluator.call.to_formatted_s(:iso8601) }
    end

    def locker
      @locker ||= TimelockEvent::Lockers::RedisLocker.new({
        key: key,
        current_time_parser: current_time_parser,
        current_time_str_generator: current_time_str_generator,
        redis_connection: redis_connection
      })
    end

    def redis_connection
      @redis_connection || raise(RedisConnectionNotSpecified)
    end

    def key
      @key || raise(LockerKeyNotDefined)
    end
  end
end
