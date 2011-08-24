module Rack::API; end
class Rack::API::DatabaseRecovery

  # When the MySQL server goes away during a request (perhaps because of pool
  # timeout), we retry once before raising the error.

  def initialize(app, options = {})
    @app = app
    @waiting_for_riak = false
  end

  def call(env)
    tries = 0
    begin
      # Call app
      tries += 1
      response = @app.call(env)
    rescue Sequel::DatabaseDisconnectError => e
      if tries < 2
        Ramaze::Log.warn "Database disconnected, retrying: #{e}"
        retry
      else
        raise
      end
    rescue Errno::ECONNREFUSED => e
      raise
    end
  end
end
