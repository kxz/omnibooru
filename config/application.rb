require File.expand_path('../boot', __FILE__)
require 'rails/all'

if defined?(Bundler)
  Bundler.require(:default, Rails.env)
end

module Danbooru
  class Application < Rails::Application

    config.active_record.schema_format = :sql
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.assets.enabled = true
    config.assets.version = '1.0'
    config.autoload_paths += %W(#{config.root}/app/presenters #{config.root}/app/logical #{config.root}/app/mailers)
    config.plugins = [:all]
    config.time_zone = 'Eastern Time (US & Canada)'
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {:enable_starttls_auto => false}
    config.action_mailer.perform_deliveries = true
    config.log_tags = [lambda {|req| "PID:#{Process.pid}"}]
  end

  I18n.enforce_available_locales = false
end
