module Rack::API; end
class Rack::API::Alive
  # Handles HAProxy lifecycle.
  #
  # Respond to /alive with an empty 200 OK document. Haproxy uses this path
  # to identify the application as alive.
  #
  # When we receive a SIGTERM, we enter state :pending. On each check to
  # /alive, Haproxy notifies us of our load-balancing state.
  #
  # X-Haproxy-Server-State: UP 2/3; name=bck/srv2; node=lb1; weight=1/2; scur=13/22; qcur=0
  #
  # The weight indicates the fraction of the cluster that this instance is providing. If the weight is lower than two-thirds, we presume the cluster has sufficient capacity for us to withdraw, and we enter state :disabled.
  #
  # In the disabled state, we continue to accept requests, but return 404 for
  # any check to /alive. When HAProxy sees this 404 response it will remove us
  # from load-balancing. When our Haproxy-Server-State becomes NOLB, we exit.

  AVAILABILITY_TARGET = 1/2.0
  TIMEOUT = 10

  ALIVE = [200, {'Content-Type' => 'text/plain', 'Content-Length' => '1'}, ['a']]
  DISABLED = [404, {'Content-Type' => 'text/plain', 'Content-Length' => '1'}, ['d']] 

  LOG = if defined? Rails
    Rails.logger
  elsif defined? Ramaze
    Ramaze::Log
  else
    raise RuntimeError.new "not sure what logger to use for alive rack middleware"
  end

  def initialize(app)
    @state = :alive
    @max_weight = 0
    @app = app

    Signal.trap 'TSTP' do
      LOG.info "Ready to shut down."
      @state = :pending

      Thread.new do
        sleep(TIMEOUT + rand(TIMEOUT))
        LOG.info "Sleeper agent committing suicide."
        Process.kill 'TERM', Process.pid
      end
    end
  end

  def call(env)
    if env['REQUEST_METHOD'] == 'OPTIONS' and env['PATH_INFO'] == '/alive'
      # Parse server state
      env['HTTP_X_HAPROXY_SERVER_STATE'] =~ /^(\w+)( \d+\/\d+)?; (.*)/
      state = $1
      opts = $3
       
      opts =~ /weight=(\d+)\/(\d+)/
      total_weight = $2.to_f
      @max_weight = total_weight if total_weight > @max_weight
      weight = $1.to_f
      predicted_availability = (total_weight - weight) / @max_weight
      
      case @state
      when :alive
        return ALIVE
      when :pending
        # Parse weight

        if predicted_availability >= AVAILABILITY_TARGET or @max_weight === 1.0
          # Enough of the cluster is free; we may disable ourselves.
          @state = :disabled
          LOG.info "Entering disabled mode"
          return DISABLED
        else
          # We're still waiting for additional cluster capacity.
          LOG.info "Waiting for cluster capacity"
          return ALIVE
        end
      when :disabled
        if state == 'NOLB'
          # Haproxy has recognized our shutdown.
          # WHO IS JOSH GROBAN!?
          LOG.info "Removed from load balancing; shutting down"
          Process.kill 'TERM', Process.pid
        end
        
        return DISABLED
      end
    else
      @app.call(env)
    end
  end
end
