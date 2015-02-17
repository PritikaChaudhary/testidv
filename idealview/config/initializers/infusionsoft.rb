Infusionsoft.configure do |config|
  config.api_url = 'tb173.infusionsoft.com' # example infused.infusionsoft.com
  config.api_key = 'f65f9f22eb0af1fb5544f6ced683aeaf'
  config.api_logger = Logger.new("#{Rails.root}/log/infusionsoft_api.log") # optional logger file
end