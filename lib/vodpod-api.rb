require 'rubygems'
require 'sequel'
require 'sequel/extensions/inflector'
require 'sequel/extensions/blank'
require 'fileutils'
require 'construct'
require 'libxml'
require 'yajl/json_gem'
require 'iconv'

# Add the directory this file resides in to the load path, so you can run the
# app from any other working directory
$LOAD_PATH.unshift(File.dirname(__FILE__))

module API
  require 'api/version'
  require 'api/config'
 
  # Performs caching operations.
  def self.cache
    @cache
  end

  def self.searcher
    @searcher ||= API::Searcher.new
  end

  # Initialize controllers and models, and sets up Ramaze.
  def self.init
    return false if @initialized
    
    self.load
    self.ramaze
    
    @initialized = true
  end

  def self.initialized?
    @initialized == true
  end

  # Loads libraries, core models, and API methods.
  def self.load
    return false if @loaded

    unless defined? Vodpod::Common
      # Look for vodpod-common at the same level as vodpod-api
      begin
        # Look in our parent directory for a separate git repo
        # $LOAD_PATH.unshift File.expand_path("#{File.dirname(__FILE__)}/../../vodpod-common/lib")
        # Look in the submodule path
        $LOAD_PATH.unshift File.expand_path("#{File.dirname(__FILE__)}/vodpod-common/lib")
        require "vodpod-common"
      rescue => e
        raise e
        puts "Couldn't find vodpod-common"
        exit 1
      end
    end

    # A few other vodpod-common requirements
    require 'vodpod/imported_video'
    require 'vodpod/video_sites'
    require 'vodpod/queued_job'
    require 'vodpod/solr_client'
    require 'vodpod/alerts'

    # Set up our DB
    def API.db=(db); Vodpod.db = db; end
    def API.db; Vodpod.db; end

    # Set up a few things in Vodpod.config
    Vodpod.config.mode = self.config.mode

    require 'api/error'
    require 'api/djson'
    require 'api/named_array'
    require 'api/named_hash'
    require File.expand_path(File.join(File.dirname(__FILE__), 'snippets/init'))
    require 'model/init'
    require 'api/searcher'
    require 'api/core'
    require 'logger'
    require 'api/blowfish'
   
    # Logging 
    FileUtils.mkdir_p config.log.root
    if config.log.sql
      # SQL logs
      self.db.logger = Logger.new(File.join(config.log.root, 'sql.log'))
    end

    @loaded = true
  end
  
  def self.loaded?
    @loaded == true
  end

  def self.metrics
    @metrics
  end

  # Restart server
  def self.restart
    begin
      stop
      # Wait for server to finish, and for the port to become available.
      sleep 1
    ensure
      start
    end
  end

  # Loads and configures Ramaze and the controllers.
  def self.ramaze
    require 'ramaze'
    
    # Ramaze roots
    Ramaze.options.roots = __DIR__
    Ramaze.options.helpers_helper.paths.unshift __DIR__

    require 'vodpod/metrics'
    require 'fork_terminator'

    require 'rack/alive'
    require 'rack/errors'
    require 'rack/jsonp'
    require 'rack/youtube_hack'
    require 'rack/metrics'
    require 'rack/database_recovery'
    require 'rack/origin'
    require 'rack/time'

    require 'controller/init'

    # Logging
    Ramaze::Log.loggers.clear
    Ramaze::Log.loggers << Logger.new(File.join(config.log.root, "#{config.mode}.log"))
    Ramaze::Log.level = Logger::Severity.const_get(config.log.level.upcase)

    # Caching
    if config.memcache.enabled
      Ramaze::Cache.options.default = Ramaze::Cache::MemCache.using(:servers => config.memcache.servers)
      Ramaze::Cache.options.session = Ramaze::Cache::MemCache.using(:servers => config.memcache.servers)
      Ramaze::Cache.add :api
      @cache = Ramaze::Cache.api

      # Test cache
      t = Time.now
      API.cache['test'] = t
      unless API.cache['test'] == t
        puts "Cache failure--check memcache?"
        Ramaze::Log.warn "Cache failure--check memcache?"
      end
    end

    # Sessions
    Ramaze.options.cache.session = Ramaze::Cache::MemCache.using(:servers => config.memcache.servers)

    # Middleware
    Ramaze.middleware! :dev do |m|
      # Note that this is broken in 1.9.
      m.use Rack::Lint
      m.use Rack::RouteExceptions
      m.use Rack::API::Alive
      m.use Rack::API::Metrics
      m.use Rack::API::Origin
      m.use Rack::CommonLogger, Ramaze::Log
      m.use Rack::API::JSONP
      m.use Rack::API::YoutubeHack
      m.use Rack::API::Errors
      m.use Rack::API::DatabaseRecovery
      m.use Ramaze::Reloader
    #  m.use Rack::ShowStatus
      m.use Rack::Head
      m.use Rack::ETag
      m.use Rack::ConditionalGet
      m.use Rack::ContentLength
      m.run Ramaze::AppMap
    end

    Ramaze.middleware! :live do |m|
      m.use Rack::API::Alive
      m.use Rack::API::Metrics
      m.use Rack::CommonLogger, Ramaze::Log
      m.use Rack::API::Origin
      m.use Rack::API::JSONP
      m.use Rack::API::YoutubeHack
      m.use Rack::API::Errors
      m.use Rack::API::DatabaseRecovery
      m.use Rack::ETag
      m.use Rack::Head
      m.use Rack::ConditionalGet
      m.use Rack::ContentLength
      m.run Ramaze::AppMap
    end

    Ramaze.options.mode = config.mode
  end

  # Start server
  def self.start
    # Metrics
    @metrics = Vodpod::Metrics.new "API #{API.config.server.port}"

    # Check PID
    if File.file? config.server.pidfile
      pid = File.read(config.server.pidfile, 20).strip
      abort "Server already running? (#{pid})"
    end

    if config.server.daemon
      fork do
        # Drop console, create new session
        Process.setsid
        exit if fork

        at_exit do
          # Remove pidfile
          FileUtils.rm(config.server.pidfile) if File.exist? config.server.pidfile
        end

        # Write pidfile
        File.open(config.server.pidfile, 'w') do |file|
          file << Process.pid
        end

        # Move to homedir; drop creation mask
        Dir.chdir config.root
        File.umask 0000

        puts "Starting server #{Process.pid} on #{config.server.port}..."

        # Drop stream handles
        STDIN.reopen('/dev/null')
        STDOUT.reopen('/dev/null', 'a')
        STDERR.reopen(STDOUT)

        # Go!
        Ramaze::Log.info "Starting API server on port #{API.config.server.port}"
        Ramaze.start(
          :adapter => API.config.server.adapter, 
          :port => API.config.server.port, :file => __FILE__
        )
        Ramaze::Log.info "Server finished."
      end
    else
      # Run in foreground.
      Ramaze::Log.info "Starting API server on port #{API.config.server.port}"
      Ramaze.start(
        :adapter => API.config.server.adapter, 
        :port => API.config.server.port, :file => __FILE__
      )
      Ramaze::Log.info "Server finished."
    end
  end

  # Stop the server
  def self.stop
    unless config.server.pidfile
      abort "No pidfile to stop."
    end

    unless File.file? config.server.pidfile
      abort "Server not running? (check #{config.server.pidfile})"
    end

    # Get PID
    pid = File.read(config.server.pidfile, 20).strip
    unless (pid = pid.to_i) != 0
      abort "Invalid process ID in pidfile (#{pid})."
    end

    puts "Shutting down server #{pid}..."
    
    # Attempt to end Ramaze.
    begin
      # Try to shut down Ramaze nicely.
      Process.kill('INT', pid)
      puts "Shut down."
      killed = true
    rescue Errno::ESRCH
      # The process doesn't exist.
      puts "No server with pid #{pid}."
      killed = true
    rescue => e
      begin
        # Try to end the process forcibly.
        puts "Server #{pid} has gone rogue (#{e}); forcibly terminating..."
        Process.kill('KILL', pid)
        puts "Killed."
        killed = true
      rescue => e2
        # That failed, too.
        puts "Unable to terminate server: #{e2}."
        killed = false
      end
    end

    # Remove pidfile if killed.
    if killed
      begin
        FileUtils.rm(config.server.pidfile)
      rescue Errno::ENOENT
        # Pidfile gone
      rescue => e
        puts "Unable to remove pidfile #{config.server.pidfile}: #{e}."
      end
    end
  end
end
