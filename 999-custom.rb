# Not working for some reason?

# Log to stdout in addition to existing logging
# Copy from 100-logster
# console = ActiveSupport::Logger.new(STDOUT)
# original_logger = Rails.logger.chained.first
# console.formatter = original_logger.formatter
# console.level = original_logger.level
# original_logger.extend(ActiveSupport::Logger.broadcast(console))
