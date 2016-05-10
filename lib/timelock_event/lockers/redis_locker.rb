class TimelockEvent
  module Lockers
    class RedisLocker
      attr_reader :key

      def initialize(key:, current_time_parser:, current_time_str_generator:, redis_connection: )
        @current_time_parser = current_time_parser
        @current_time_str_generator = current_time_str_generator
        @redis_connection = redis_connection
        @key = key
      end

      def last_scheduled_at
        if scheduled_at = redis_connection.get(scheduled_at_key)
          current_time_parser.call(scheduled_at)
        end
      end

      def last_finished_at
        if finished_at = redis_connection.get(finished_at_key)
          current_time_parser.call(finished_at)
        end
      end

      def log_as_scheduled
        redis_connection.set(scheduled_at_key, current_time_string)
      end

      def log_as_finished
        redis_connection.set(finished_at_key, current_time_string)
      end

      private
        attr_reader :current_time_parser, :current_time_str_generator, :redis_connection

        def scheduled_at_key
          "#{key}:scheduled_at"
        end

        def finished_at_key
          "#{key}:finish_at"
        end

        def current_time_string
          current_time_str_generator.call
        end
    end
  end
end
