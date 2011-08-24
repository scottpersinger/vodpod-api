require 'date'
Terminator.signal = 'USR2'
Signal.trap('USR2', 'IGNORE')

class API::Controller < Ramaze::Controller
  helper :error
 
  # JSON
  provide(:json, :type => 'application/json') do |action, value|
    value
  end
  provide(:js, :type => 'application/json') do |action, value|
    value
  end

  # XML
  provide(:xml, :type => 'text/xml') do |action, value|
    value
  end

  # Human-readable
  provide(:html, :type => 'text/plain') do |action, value|
    value
  end
  provide(:txt, :type => 'text/plain') do |action, value|
    value
  end

  layout nil
  engine :None

  CONTENT_TYPES = {
    'json' => 'application/json',
    'js' => 'application/json',
    'xml' => 'text/xml',
    'txt' => 'text/plain; charset=utf-8',
    nil => 'text/plain; charset=utf-8'
  }

  class TimeoutError; end
  TIMEOUT = case API.config.mode
  when :live
    8
  else
    4
  end

  def self.handler_opts
    @handler_opts ||= {}
  end

  # Sets the caching policy for the next handler. Keys is an array of
  # request parameters to use as the cache key.
  #
  # Opts can include:
  #
  # :ttl - Time before cache expiry.
  # :proc - Receives a hash with keys
  #   :request,
  #   :method,
  #   :args,
  #   :format
  #   
  #   and returns a string which is used as a part of the cache key.
  def self.cache_with(keys, opts = {}, &block)
    @next_cache_opts = {:keys => keys.sort}.merge opts
    @next_cache_opts[:ttl] ||= 300
    if block
      @next_cache_opts[:proc] = block
    end
  end

  # Each node of the tree is a hash.
  #
  # node = {'users' => ..., 'videos' => ...}
  #
  # The strings correspond to literal path fragments. If the path fragment
  # matches one, we descend into that node.
  #
  # If hash.default exists, we store the current fragment in the arg list and
  # descend into that node.
  #
  # Otherwise, we abort with 404.
  #
  # Once we've finished traversing the path, we're looking at a hash.
  #
  # node[nil] should be a symbol corresponding to the method to call.
  def self.handlers
    @handlers ||= {}
  end

  def self.h(*spec, &block)
    method_name = ('h_' + spec.join('_')).to_sym
    define_method method_name, &block

    # Insert the symbol into the handlers tree.
    node = handlers
    spec.each do |fragment|
      case fragment
      when :**
        # Insert a multi-glob node.
        node = (node[:**] ||= {})
      when :*
        # Insert a glob node.
        node = (node[:*] ||= {})
      when String
        # Insert a literal node.
        node = (node[fragment] ||= {})
      else
        raise ArgumentError, "invalid handler spec fragment #{fragment.inspect}"
      end
    end

    # And now set the method name.
    node[nil] = method_name

    # Set the cache options for this method.
    timeout = case @next_timeout_opts
              when false
                nil
              when nil
                TIMEOUT
              else
                @next_timeout_opts
              end

    handler_opts[method_name] = {
      :cache => @next_cache_opts,
      :timeout => timeout
    }

    @next_cache_opts = nil
    @next_timeout_opts = nil
  end
  
  # Sets the timeout for the next handler.
  def self.timeout(time)
    @next_timeout_opts = time
  end

  def index(*fragments)
    API.metrics.poll

    node = self.class.handlers
    args = []

    # Traverse the tree!
    fragments.each_with_index do |fragment, i|
      if node.include? fragment
        # Literal
        node = node[fragment]
      elsif node.include? :**
        # Multiglob
        args += fragments[i..-1]
        node = node[:**]
        break
      elsif node.include? :*
        # Glob
        args << fragment
        node = node[:*]
      else
        error_404
      end
    end

    # OK, now get the method for this node.
    node = node[nil] || node[:**][nil] rescue error_404

    # We should have a symbol now!
    error_404 unless node.kind_of? Symbol

    # Log request
    Ramaze::Log.info "REQ #{@client ? @client.key : ''} #{node}(#{args.join(', ')})"

    # Now just call the appropriate method with args.
    result = call_with_timeout(node, args)
    if result == Error
      Ramaze::Log.error "timeout: #{@client ? @client.key : ''} #{node}(#{args.join(', ')})"
      raise API::Error, 'timed out'
    else
      result
    end
  end

  private

  def call_with_timeout(method, args)
    timeout = self.class.handler_opts[method][:timeout]

    if @timeout_running or timeout.nil?
      # Timeout already running, invoke
      call_with_cache(method, args)
    else
      @timeout_running = true
      begin
        Terminator.terminate(
          :seconds => timeout,
          :trap => Proc.new { return Error }
        ) do
          call_with_cache(method, args)
        end
      ensure
        @timeout_running = false
      end
    end
  end

  # Checks the cache for the given method and invokes it with args, caching
  # the result if necessary.
  def call_with_cache(method, args)
    if opts = self.class.handler_opts[method][:cache]
      begin
        # If there are uncacheable parameters, abort and just call the method.
        raise unless (request.params.keys - self.class::KEYS - opts[:keys]).empty?

        # Compute cache key for this method, args, and params.
        args_key = args.map { |a| escape a }.join("&")
        
        opts_key = opts[:keys].map { |k|
          escape request.params[k]
        }.join("&")

        format_key = request.path[/\.(\w+)$/, 1]
        
        if opts[:proc]
          result = opts[:proc].call(
            :method => method,
            :args => args,
            :request => request,
            :format => format_key,
            :client => @client
          )
          if result
            proc_key = escape result
          else
            # Don't cache.
            raise
          end
        else
          proc_key = ''
        end
        
        key = "#{self.class}/#{method}/#{args_key}/#{opts_key}/#{proc_key}/#{format_key}"

        # Check the cache and attempt to respond immediately.
        if value = API.cache[key]
          Ramaze::Log.info "Cache hit"
          response['Content-Type'] = CONTENT_TYPES[format_key]
          return value
        end

        # Nope? Invoke the method and cache the result.
        value = format(send(method, *args))

        API.cache.store key, value, :ttl => opts[:ttl]
      rescue => e
        # Under no circumstances are we to cache something weird, like a file.
        # If that were to happen, we'd hit an error in escape().
        format(send(method, *args))
      end
    else
      format(send(method, *args))
    end
  end

  # Escapes string for cache keys.
  def escape(string)
    return "" if string.nil?
    string = ':' + string.to_s if string.kind_of? Symbol
    string.gsub("\\", "\\\\").gsub("&", "\&").gsub(":", "\:").gsub("/", "\/")
  end

  # Formats a response by extension.
  # Formatting occurs only once; the presence of Content-Type will prevent it.
  # This is to prevent cached data or requests which are routed through index
  # multiple times from being reformatted
  def format(value)
    return value if response['Content-Type']

    type = request.path[/\.(\w+)$/, 1]
    response['Content-Type'] = CONTENT_TYPES[type]

    case type
    when nil, 'txt'
      JSON.pretty_generate([true, value])
    when 'js', 'json'
      [true, value].to_json
    when 'xml'
      doc = LibXML::XML::Document.new
      value = value.to_xml
      if value.text?
        # Wrap text nodes in a root node.
        root = LibXML::XML::Node.new('message')
        root << value
        doc.root = root
      else
        doc.root = value
      end
      doc
    else
      error_404
    end
  end

  def method_name
    caller[0] =~ /`([^']*)'/ and $1
  end
end

require 'controller/main'
require 'controller/doc'
require 'controller/twitter'
