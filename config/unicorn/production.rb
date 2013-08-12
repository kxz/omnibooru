# Set your full path to application.
app_path = "/srv/danbooru2/current"

# Set unicorn options
worker_processes 4

preload_app false
timeout 180
listen "#{app_path}/tmp/sockets/unicorn.sock"

# Spawn unicorn master worker for user apps (group: apps)
user 'danbooru'

# Fill path to your app
working_directory app_path

# Should be 'production' by default, otherwise use other env
rails_env = ENV['RAILS_ENV'] || 'production'

# Log everything to one file
stderr_path "log/unicorn.log"
stdout_path "log/unicorn.log"

# Set master PID location
pid "#{app_path}/tmp/pids/unicorn.pid"

ENV["RAILS_RELATIVE_URL_ROOT"] = "/booru"

# before_fork do |server, worker|
#   ActiveRecord::Base.connection.disconnect!

#   old_pid = "#{server.config[:pid]}.oldbin"
#   if File.exists?(old_pid) && server.pid != old_pid
#     begin
#       Process.kill("QUIT", File.read(old_pid).to_i)
#     rescue Errno::ENOENT, Errno::ESRCH
#       # someone else did our job for us
#     end
#   end
# end

# after_fork do |server, worker|
#   ActiveRecord::Base.establish_connection
# end
