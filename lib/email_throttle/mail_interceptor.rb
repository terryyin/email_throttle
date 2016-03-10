module EmailThrottle
  class MailInterceptor
    def self.delivering_email(message)
      if async_deliver? and not message.instance_variable_get(:@sync)
        if message.header[:importance].try(:value) != "High"
          EmailThrottle::DailyWorker.perform_async message.to_yaml
        else
          EmailThrottle::Worker.perform_async message.to_yaml
        end
        message.perform_deliveries = false
      end
    end

    def self.async_deliver?
      !Rails.env.test?
    end
  end
end
