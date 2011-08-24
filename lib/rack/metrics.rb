module Rack::API; end
class Rack::API::Metrics
  # Logs request times to API.metrics.
  def initialize(app)
    @app = app
  end

  def call(env)
    t1 = Time.now
    response = @app.call(env)
    t2 = Time.now

    API.metrics << (t2-t1)

    response
  end
end
