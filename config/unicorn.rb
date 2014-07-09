require "#{File.expand_path('../', File.dirname(__FILE__))}/env"

APP_ROOT = File.expand_path '../', File.dirname(__FILE__)

worker_processes ENV["UNICORN_WORKERS"].to_i

working_directory APP_ROOT

pid "#{APP_ROOT}/tmp/pids/unicorn.pid"

listen "#{APP_ROOT}/tmp/sockets/unicorn.sock"

stderr_path "#{APP_ROOT}/log/unicorn.stderr.log"
stdout_path "#{APP_ROOT}/log/unicorn.stdout.log"

preload_app true

before_fork do |server, worker|
  old_pid = "#{APP_ROOT}/tmp/pids/unicorn.pid.oldbin"

  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) && ActiveRecord::Base.establish_connection
  child_pid = server.config[:pid].sub('.pid', ".#{worker.nr}.pid")
  system("echo #{Process.pid} > #{child_pid}")
end
