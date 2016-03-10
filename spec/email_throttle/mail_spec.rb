require 'sidekiq/testing'

describe EmailThrottle, scope: :integration do

  describe "email send to job" do

    before {
      Sidekiq::Testing.fake!
      allow(EmailThrottle::MailInterceptor).to receive(:async_deliver?) {true}
    }

    subject {
        ActionMailer::Base.mail(
        from:"me@m.com",
        to:"you@m.com",
        subject:"s",
        body:"my email",
        importance: @importance).deliver_now
    }

    it 'will override sending mail with ActionMailer' do
      expect {subject
      }.to change(EmailThrottle::DailyWorker.jobs, :size).by(1)
      expect(EmailThrottle::DailyWorker.jobs.last['queue']).to eq 'mailer_low'
    end

    it 'be ok if no importance' do
      expect {
        ActionMailer::Base.mail(
        from:"me@m.com",
        to:"you@m.com",
        subject:"s",
        body:"my email").deliver_now
      }.to change(EmailThrottle::DailyWorker.jobs, :size).by(1)
      expect(EmailThrottle::DailyWorker.jobs.last['queue']).to eq 'mailer_low'
    end

    it 'will skip DailyWorker for important emails' do
      @importance = "High"
      expect {subject
      }.to change(EmailThrottle::DailyWorker.jobs, :size).by(0)
    end

    it 'will send to Worker for important emails' do
      @importance = "High"
      expect {subject
      }.to change(EmailThrottle::Worker.jobs, :size).by(1)
    end

    it 'daily worker calls worker' do
      EmailThrottle::DailyWorker.drain
      expect {
        EmailThrottle::DailyWorker.perform_async(nil)
        EmailThrottle::DailyWorker.drain
      }.to change(EmailThrottle::Worker.jobs, :size).by(1)
      expect(EmailThrottle::Worker.jobs.last['queue']).to eq 'mailer_low'
    end

    it {expect{subject}.to change(pending_emails, :length).by(0)}

    it {
      Sidekiq::Testing.inline!
      expect{subject}.to change(pending_emails, :length).by(1)
      expect(pending_emails.last.body).to include "my email"
    }


    it 'will set a default retry delay' do
      expect(EmailThrottle::Worker.sidekiq_retry_in_block.call).to eq 60 * 60 # 1 hour
    end

    it {
      #expect(EmailThrottle::Worker.get_sidekiq_options['throttle']).to eq({ threshold: 10, period: 20.seconds})
    }

    it {
      #expect(EmailThrottle::DailyWorker.get_sidekiq_options['throttle']).to eq({ threshold: 1800, period: 24.hours })
    }

  end
end
