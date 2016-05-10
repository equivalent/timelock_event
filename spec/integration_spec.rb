require 'spec_helper'

class IntegrationDummy1
  def self.timelocker
    config = TimelockEvent::Config.new
    config.redis_connection = test_redis
    config.key = 'test_gem_timelock_event_IntegrationDummy1'

    TimelockEvent.new(config: config)
  end

  def self.memoize_timelocker
    @memoize_timelocker ||= begin
      config = TimelockEvent::Config.new
      config.redis_connection = test_redis
      config.key = 'test_gem_timelock_event_IntegrationDummy2'

      TimelockEvent.new(config: config)
    end
  end
end

RSpec.describe IntegrationDummy1 do
   # integration test of gem timelock_event

  def scheduled_at_key
    timelocker
      .send(:locker)
      .send(:scheduled_at_key)
  end

  def finished_at_key
    timelocker
      .send(:locker)
      .send(:finished_at_key)
  end

  def trigger
    timelocker.transaction { execution_spy.call }
  end

  let(:execution_spy) { spy }


  %w(timelocker memoize_timelocker).each do |usecase_method|
    describe ".#{usecase_method}" do
      let(:timelocker) { described_class.send(usecase_method) }

      before do
        test_redis.del(scheduled_at_key)
        test_redis.del(finished_at_key)
      end

      context 'given it\'s peek hour' do
        before do
          expect(Time)
            .to receive(:now)
            .at_least(:once)
            .and_return(Time.parse("2016-04-27 01:59:00 +0100"))

          trigger
        end

        it "don't execute" do
          expect(execution_spy).not_to have_received(:call)
        end
      end

      context 'given not a peek hour' do
        before do
          expect(Time)
            .to receive(:now)
            .at_least(:once)
            .and_return(Time.parse("2016-04-27 02:00:00 +0100"))

          trigger
        end

        it "should execute" do
          expect(execution_spy).to have_received(:call)
        end

        context 'executed twice' do
          it do
            trigger
            expect(execution_spy).to have_received(:call).once
          end
        end
      end
    end
  end
end
