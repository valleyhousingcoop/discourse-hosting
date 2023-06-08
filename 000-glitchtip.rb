require "resolv-replace"

Sentry.init do |config|
  config.breadcrumbs_logger = %i[
    sentry_logger
    active_support_logger
    http_logger
  ]
  config.include_local_variables = true
  config.send_default_pii = true
  # Disable session tracking since not supported by glitchtip
  # https://gitlab.com/glitchtip/glitchtip-backend/-/issues/206
  config.auto_session_tracking = false

  # Disable client reports since not supported by glitchtip
  config.send_client_reports = false

  config.traces_sample_rate = 0.1
  # Upload whole traceback on error
  config.debug = true
end

# Patch Discourse's warn_exception to send exceptions to Sentry as well
# Patch code from https://blog.appsignal.com/2021/08/24/responsible-monkeypatching-in-ruby.html

module DiscourseWarnExceptionMonkeypatch
  class << self
    def apply_patch
      const = find_const
      mtd = find_method(const)

      # make sure the class we want to patch exists;
      # make sure the #build_hidden method exists and accepts exactly
      # two arguments
      unless const && mtd
        raise "Could not find class or method when patching " \
                "Discourse's warn_exception helper. Please investigate."
      end

      # actually apply the patch
      const.prepend(InstanceMethods)
    end

    private

    def find_const
      Kernel.const_get("Discourse")
    rescue NameError
      # return nil if the constant doesn't exist
    end

    def find_method(const)
      return unless const
      const.method(:warn_exception)
    rescue NameError
      # return nil if the method doesn't exist
    end
  end

  module InstanceMethods
    # https://blog.daveallie.com/clean-monkey-patching#prepending-a-module
    def self.prepended(base)
      base.singleton_class.prepend(ClassMethods)
    end

    module ClassMethods
      def warn_exception(e, message: "", env: nil)
        Sentry.capture_exception(e, extra: env)
        super
      end
    end
  end
end

DiscourseWarnExceptionMonkeypatch.apply_patch
