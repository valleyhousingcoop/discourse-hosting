Rails.application.config.after_initialize do
  console = ActiveSupport::Logger.new(STDOUT)
  original_logger = Rails.logger.chained.first
  console.formatter = original_logger.formatter
  console.level = original_logger.level

  unless ActiveSupport::Logger.logger_outputs_to?(original_logger, STDOUT)
    original_logger.extend(ActiveSupport::Logger.broadcast(console))
  end
end
