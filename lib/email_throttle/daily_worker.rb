module EmailThrottle
  class DailyWorker
    include Sidekiq::Worker
    sidekiq_options queue: :mailer_low, retry: 2, backtrace: true
    sidekiq_options throttle: { threshold: 1800, period: 24.hours }

    sidekiq_retry_in do |count|
      60 * 60
    end

    def perform(mail_yaml)
      EmailThrottle::Worker.perform_async mail_yaml
    end
  end
end


