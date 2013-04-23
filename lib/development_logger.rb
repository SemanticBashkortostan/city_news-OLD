module DevelopmentLogger


  def logger
    logger = Logger.new("#{Rails.root}/log/custom_development.log")
    logger.formatter = Logger::Formatter.new
    logger
  end


  def self.logger
    logger = Logger.new("#{Rails.root}/log/custom_development.log")
    logger.formatter = Logger::Formatter.new
    logger
  end


end