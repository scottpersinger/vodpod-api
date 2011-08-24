# Just for fun...
at_exit do
  if Bacon::Counter[:errors] + Bacon::Counter[:failed] == 0 and Bacon::Counter[:passed] > 0
    fork do
      exec "mpg321 -q #{Ramaze.options.roots.first}/data/monsterkill.mp3 2>&1 >/dev/null"
    end
  end
end

shared :api do
  
  # Make a JSON request for the specified path and params. Uses my API key if
  # none given. If a block given, yields the hash to the block. If an error is
  # returned, prints the error and stacktrace. The returned object is the data
  # alone.
  def json(path, params = {}, env = {}, &block)
    params = {:api_key => '5c87948ac1979401'}.merge params
    json = json_plain(path, params, env)
    if json[0].false?
      puts
      if json[1]['errors']
        p json[1]['errors']
      else
        puts "Server Error: #{json[1]['message']}"
        puts json[1]['backtrace'].split("\n")[0..20].join("\n") + "\n..."
      end
      raise json[1]['message']
    end
    if block_given?
      yield json[1]
    else
      json[1]
    end
  end

  # Checks to ensure the request gives an error, and returns the message.
  def json_error(*args, &block)
    json = json_plain(*args)
    json[0].should.be.false
    if block_given? 
      yield json[1]
    end
    json[1]
  end

  # Same as json, without error checking. The returned object is the full
  # response.
  def json_plain(path, params = {}, env = {}, &block)
    params = {:api_key => '5c87948ac1979401'}.merge params
    meth = params.delete(:method) || :get
      
    json = JSON.parse(send(meth, path + '.json', params, env).body)
    
    if block_given?
      yield json
    else
      json
    end
  end

  # Make an XML request for the specified path and params. Uses my API key if none given. If a block given, yields the hash to the block. If an error is returned, prints the error and stacktrace.
  def xml(path, params = {}, env = {}, &block)
    params = {:api_key => '5c87948ac1979401'}.merge params
    xml = LibXML::XML::Parser.string(get(path + '.xml', params, env).body).parse
    if error = xml.find('/error').first
      message = error.find_first('message')
      puts
      puts "Server Error: #{message.content}"
      backtrace = error.find_first('backtrace')
      puts backtrace.content
      exit!
    end
    if block_given?
      yield xml
    else
      xml
    end
  end

  def under(t)
    t1 = Time.now
    x = yield
    t2 = Time.now
    (t2 - t1).should < t
    x
  end
end

shared :facebook do
  # Returns an auth code.
  def facebook_login(uri, email, pass)
    a = Mechanize.new
    a.user_agent_alias = "Mac Mozilla"

    page = a.get uri
    login = page.form_with(:action => /https?:\/\/\w+.facebook\.com\/login.php/)
    login['email'] = email
    login['pass'] = pass

    a.post_connect_hooks << proc do |agent, uri|
      if code = uri.query[/code=(.+?)($|&)/, 1]
        return code
      end
    end
    page = login.submit(login.button_with(:value => 'Log In'))
    
    unless code = page.root.to_s[/.*code=(.+)(&|")/,1]
      form = page.form_with(:action => /https?:\/\/www\.facebook\.com\/connect\/uiserver\.php/)
      page = form.submit(form.button_with(:value => 'Allow'))
      code = page.root.to_s[/.*code=(.+)(&|")/,1]
    end
    code = Rack::Utils.unescape(code.gsub('\u0025', '%'))

    code.should.not.be.blank

    code
  end
end
