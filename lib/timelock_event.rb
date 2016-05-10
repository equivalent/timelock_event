require 'active_support/core_ext/numeric/time.rb'
require 'redis'
require 'ostruct'
require 'forwardable'
require "timelock_event/version"
require "timelock_event/config"
require "timelock_event/lockers/redis_locker"

class TimelockEvent
  extend Forwardable

  def self.config
    @config ||= Config.new
  end

  attr_reader :config
  def_delegators :locker, :last_finished_at, :last_scheduled_at
  def_delegators :config, :unlock_hour_window, :lock_for

  def initialize config: TimelockEvent.config
    @config = config
  end

  def locked?
    (current_time.to_i - last_scheduled_at.to_i) > lock_for.to_i
  end

  def performable?
    transaction_window_open && locked?
  end

  def transaction(&block)
    if performable?
      log_as_scheduled
      yield
      log_as_finished
    end
  end

  private
    def_delegators :locker, :log_as_scheduled, :log_as_finished
    def_delegators :config, :locker, :current_time_evaluator

    def close_hour
      unlock_hour_window.last
    end

    def open_hour
      unlock_hour_window.first
    end

    def current_time
      current_time_evaluator.call
    end

    def transaction_window_open
      current_time.hour >= open_hour \
        && current_time.hour <  close_hour
    end
end
