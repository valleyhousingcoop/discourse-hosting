Sentry.init do |config|

  # this gem also provides a new breadcrumb logger that accepts instrumentations from ActiveSupport
  # it's not activated by default, but you can enable it with
  # config.breadcrumbs_logger = [:active_support_logger]

  config.dsn =  ENV['SENTRY_DSN']
end
