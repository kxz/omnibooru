require File.expand_path('../../state_checker', __FILE__)

StateChecker.new.check!

Rails.application.config.action_dispatch.session = {
  :key    => '_danbooru2_session',
  :secret => File.read(File.expand_path("#{Rails.root}/config/session_secret_key"))
}
Rails.application.config.secret_token = File.read(File.expand_path("#{Rails.root}/config/secret_token"))
