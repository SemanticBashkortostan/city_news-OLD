module BayesLogger


  def bayes_logger
    logger = Logger.new("#{Rails.root}/log/bayes.log")
    logger.formatter = Logger::Formatter.new
    logger
  end


  def self.bayes_logger
    logger = Logger.new("#{Rails.root}/log/bayes.log")
    logger.formatter = Logger::Formatter.new
    logger
  end


end