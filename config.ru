# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

if defined? Unicorn
  require_dependency 'gctools/oobgc'
  use GC::OOB::UnicornMiddleware
end

map (ENV['RAILS_RELATIVE_URL_ROOT'] || '/') do
  run Rails.application
end
