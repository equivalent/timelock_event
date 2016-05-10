require 'spec_helper'

class IntegrationDummy1
  def self.timelocker
    config = TimelockEvent::Config.new
    config.redis_connection = test_redis
    config.key = 'test_gem_timelock_event_IntegrationDummy1'

    TimelockEvent.new(config: config)
  end
end

RSpec.describe IntegrationDummy1 do

  describe '.timelocker' do
    # integration test of gem timelock_event

    let(:timelocker) { described_class.timelocker }

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

    before do
      test_redis.del(scheduled_at_key)
      test_redis.del(finished_at_key)
    end

    let(:execution_spy) { spy }

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
