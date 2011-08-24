# configiguration schema
module API
  def self.config_file
    @config_file ||= 'api.conf'
  end

  def self.config_file=(file)
    @config_file = file
  end

  def self.config
    return @config if @config

    # Load configuration
    if File.exists? self.config_file
      config = Construct.load(File.read(config_file))
    else
      config = Construct.load(
        File.read(
          File.join(
            File.dirname(__FILE__), '..', '..', 'proto', 'api.conf'
          )
        )
      )
    end

    config.define :root, :default => Dir.pwd

    config.define :mode, :default => :live

    config.define :adapter, :default => false

    config.define :memcache, :default => Construct.new
    config.memcache.define :enabled, :default => true
    config.memcache.define :servers, :default => ['localhost:11211:1']

    config.define :server, :default => Construct.new
    config.server.define :port, :default => 8000
    config.server.define :adapter, :default => :thin
    config.server.define :pidfile, 
      :default => File.join(config.root, "api_#{config.server.port}.pid")
    config.server.define :daemon
    server = config.server
    def server.daemon
      if include? :daemon
        self[:daemon]
      else
        API.config.mode == :live
      end
    end

    config.define :solr, :default => Construct.new
    config.solr.define :port, :default => 8983
    config.solr.define :host, :default => 'localhost'
    config.solr.define :timeout, :default => 5
    config.solr.define :maximum_limit, :default => 50
    config.solr.define :default_limit, :default => 10

    config.define :site, :default => Construct.new
    config.site.define :vodpod_url, :default => 'http://vodpod.com'

    config.define :include_limit, :default => 12
    config.define :include_tags_limit, :default => 20
    
    # Logging
    config.define :log, :default => Construct.new
    config.log.define :root, :default => File.join(Dir.pwd, 'log')
    config.log.define :sql, :default => true if config.mode == :dev
    config.log.define :sql, :default => false if config.mode == :live
    config.log.define :level, :default => 'info' if config.mode == :live
    config.log.define :level, :default => 'debug' if config.mode == :dev

    @config = config
  end
end
