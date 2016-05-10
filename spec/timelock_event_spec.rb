require 'spec_helper'

describe TimelockEvent do
  before { TimeStub.current_time = Time.now }

  it 'has a version number' do
    expect(TimelockEvent::VERSION).not_to be nil
  end

  def scheduled_at_key
    subject
      .send(:locker)
      .send(:scheduled_at_key)
  end

  def finished_at_key
    subject
      .send(:locker)
      .send(:finished_at_key)
  end

  let(:redis_key) { 'TestTimelockEvent' }
  let(:block_trigger) { spy }

  before do
    test_redis.del(scheduled_at_key)
    test_redis.del(finished_at_key)
  end

  context 'running first time' do
    context 'in a transaction time window' do
      before { TimeStub.current_time = Time.parse('2016-04-27 02:00:00 +0100') }

      it { expect(subject).to be_locked }
      it { expect(subject).to be_performable }

      it do
        subject.transaction { block_trigger.executed }
        expect(block_trigger).to have_received :executed
      end
    end
  end

  context 'was processed before' do
    before do
      test_redis.set(scheduled_at_key, Time.parse("2016-04-25 16:59:00 +0100"))
    end

    context 'less than `lock_for` period passed since last perform' do
      before { TimeStub.current_time = Time.parse("2016-04-26 16:00:00 +0100") }

      it { expect(subject).not_to be_locked }
      it { expect(subject).not_to be_performable }

      it do
        subject.transaction { block_trigger.executed }
        expect(block_trigger).not_to have_received :executed
      end
    end

    context '`lock_for` period satisfied since last perform but not in transaction time window' do
      before { TimeStub.current_time = Time.parse("2016-04-26 17:00:00 +0100") }

      it { expect(subject).to be_locked }
      it { expect(subject).not_to be_performable }

      it do
        subject.transaction { block_trigger.executed }
        expect(block_trigger).not_to have_received :executed
      end
    end

    context '`lock_for` period satisfied since last perform but not in transaction time window' do
      before { TimeStub.current_time = Time.parse("2016-04-27 01:59:00 +0100") }

      it { expect(subject).to be_locked }
      it { expect(subject).not_to be_performable }

      it do
        subject.transaction { block_trigger.executed }
        expect(block_trigger).not_to have_received :executed
      end
    end

    context '`lock_for` period satisfied since last perform and in a transaction time window' do
      before { TimeStub.current_time = Time.parse('2016-04-27 02:00:00 +0100') }

      it { expect(subject).to be_locked }
      it { expect(subject).to be_performable }

      it do
        subject.transaction { block_trigger.executed }
        expect(block_trigger).to have_received :executed
      end
    end

    context '`lock_for` period satisfied since last perform and  transaction time window passed' do
      before { TimeStub.current_time = Time.parse("2016-04-27 05:00:01 +0100") }

      it { expect(subject).to be_locked }
      it { expect(subject).not_to be_performable }

      it do
        subject.transaction { block_trigger.executed }
        expect(block_trigger).not_to have_received :executed
      end
    end
  end

  describe '#transaction' do
    # behevaior is captured in specs above this is mockist unit test
    def current_time
      Time.now
    end

    it do
      expect(subject.last_scheduled_at).to be nil
      expect(subject.last_finished_at).to be nil
      expect(subject).to receive(:performable?).and_return(true)

      subject.transaction do
        block_trigger.executed
        expect(subject.last_scheduled_at).to be_within(1.minute).of(Time.now)
        expect(subject.last_finished_at).to be nil
      end

      expect(block_trigger).to have_received :executed

      expect(subject.last_scheduled_at).to be_within(1.minute).of(Time.now)
      expect(subject.last_finished_at).to be_within(1.minute).of(Time.now)
    end
  end
end
