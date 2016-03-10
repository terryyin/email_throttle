# Email Throttle

This is extracted from my other private RoR project, where I used to use
Google mail to send emails and need to be careful not to send too many
emails in a short time and not too many emails for every day. Now I
switched to a comercial email sending services so this piece of code is no
longer needed. Hopefully, it can be useful for anybody who want to send
email with throttle control.

You need `sidekiq` to make this piece of code work.

And in an initializer, put:

    ActionMailer::Base.register_interceptor(EmailThrottle::MailInterceptor)
