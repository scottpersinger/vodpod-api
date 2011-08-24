class Rack::API::Time
  def initialize(app)
    @app = app
  end

  def call(env)
    t1 = Time.now
    x = @app.call(env)
    Ramaze::Log.info "ramaze in #{Time.now - t1}"
    x
  end
end
