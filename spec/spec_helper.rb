$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'timelock_event'

TEST_REDIS_CREDENTIALS = 

def test_redis
  test_redis ||= Redis.new({
  host: ENV['TEST_REDIS_HOST'] || raise('pls specify TEST_REDIS_HOST'),
  port: ENV['TEST_REDIS_PORT'] || 6379,
  db: ENV['TEST_REDIS_PORT'] || 0
})
end

class TimeStub
  class << self
    attr_accessor :current_time
  end
end

TimelockEvent.config.redis_connection = test_redis
TimelockEvent.config.current_time_evaluator = ->{ TimeStub.current_time }
TimelockEvent.config.key = 'test_gem_timelock_event'
