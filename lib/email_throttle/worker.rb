module EmailThrottle
  class Worker
    include Sidekiq::Worker
    sidekiq_options queue: :mailer_low, retry: 3, backtrace: true
    sidekiq_options throttle: { threshold: 10, period: 20.seconds }

    sidekiq_retry_in do |count|
      60 * 60
    end

    def perform(mail_yaml)
      m = ::Mail::Message.from_yaml mail_yaml
      m.instance_variable_set(:@sync, true)
      m.deliver
    end
  end
end

