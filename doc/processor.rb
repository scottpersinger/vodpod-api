#!/usr/bin/ruby

require 'rubygems'
require 'yaml'
require 'bluecloth'
require 'pp'
require 'httparty'
require 'addressable/uri'
require 'json'
require 'ramaze'
require __DIR__('../lib/vodpod-api')
API.load

def path_to_id(path)
  path.gsub('/','_').gsub(/<|&lt;/, '(').gsub(/>|&gt;/, ')')
end

def h(str)
  str = Rack::Utils.escape_html(str)
  str = str.gsub(/_([\w_]+)_/) { |m| "<code>#{$1}</code>" }
end

def hb(str)
  str = BlueCloth::new(h(str)).to_html 
  str = linkify str
end

def get(path, opts = {})
  method = opts.delete(:method) || :get
  uri = Addressable::URI.parse(path)
  uri_opts = opts.merge(uri.query_values || {})
  uri_opts['api_key'] ||= '123456'
  if uri_opts['auth_key']
    uri_opts['auth_key'] = 'cb729c662fdb4f59'
  end
  uri.query_values = uri_opts
  uri.host = 'localhost'
  uri.port = 8000
  uri.scheme = 'http'
  puts "#{method} #{uri}"
  case method
  when :post
    uri.query_values = nil
    HTTParty.post(uri.to_s, uri_opts).body
  else
    HTTParty.send(method, uri.to_s).body
  end
end

def json(path, opts = {})
  uri = Addressable::URI.parse(path)
  uri.path = uri.path + '.json'
  JSON.pretty_generate(
    JSON.parse(get(uri.to_s, opts))
  )
end

def linkify(str)
  str = str.dup
  str.gsub!(/(>|\s)(\/[\w\d\/&;]*)/) { |m|
    if @paths.include? $2
      $1 + '<a href="/v2/doc/paths/' + path_to_id($2) + '.html">' + $2 + '</a>' 
    else
      $1 + $2
    end
  }

  @objects.sort{|a,b| b[0].length <=> a[0].length}.each do |object, desc|
    str.gsub!(/(\s)(<a[^>]*>)?(#{object})(s)?/) do |m|
      if $2
        "#{$1}#{$2}#{$3}#{$4}"
        m
      else
        "#{$1}<a href=\"/v2/doc/objects/#{object}.html\">#{$3}#{$4}</a>"
      end
    end
  end

  str
end

def path_link(path)
  '<a href="/v2/doc/paths' + path_id(path) + '.html">' + h(path) + '</a>'
end

def obj_link(obj)
  '<a href="/v2/doc/objects' + obj + '.html">' + obj + '</a>'
end

def xml(path, opts = {})
  uri = Addressable::URI.parse(path)
  uri.path = uri.path + '.xml'
  get(uri.to_s, opts)
end

@out_dir = __DIR__('../lib/public/doc')

d = YAML::load(File.read(__DIR__("paths.yaml")))
d = d.sort_by { |p| p['path'].split('/') }
@paths = d.map { |p| h p['path'] }
o = YAML::load(File.read(__DIR__("objects.yaml")))
@objects = o.sort

File.open("#{@out_dir}/guide.html", 'w') do |f|
  f << File.read('doc/preamble.html')
  f << File.read('doc/guide.html')
end

File.open("#{@out_dir}/tutorial.html", 'w') do |f|
  f << File.read('doc/preamble.html')
  f << File.read('doc/tutorial.html')
end

File.open("#{@out_dir}/tos.html", 'w') do |f|
  f << File.read('doc/preamble.html')
  f << File.read('doc/tos.html')
end

File.open("#{@out_dir}/jquery.html", 'w') do |f|
  f << File.read('doc/preamble.html')
  f << File.read('doc/jquery.html')
end

File.open("#{@out_dir}/index.html", 'w') do |f|
  f << File.read('doc/preamble.html')
  f << File.read('doc/index.html')

  # Objects
  f << '<div id="objects">'
  f << '<h2>Objects</h2>'
  f << "<ul>"
  o.sort.each do |name, obj|
    f << "<li><a href=\"/v2/doc/objects/#{name}.html\">#{h name}</a></li>\n"
  end
  f << "</ul>"
  f << "</div>\n"

  # Paths
  f << '<div id="paths">'
  f << '<h2>Paths</h2>'

  f << "<ul>"
  d.each do |path|
    f << "<li><a href=\"/v2/doc/paths/#{path_to_id(path['path'])}.html\">#{h path['path']}</a></li>\n"
  end
  f << "</ul>"
  f << "</div>"
  f << "</div>\n"
  f << "</body>"
  f << "</html>"
end

# Objects
o.sort.each do |name, obj|
  File.open("#{@out_dir}/objects/#{name}.html", 'w') do |f|
    f << File.read('doc/preamble.html')

    f << '<div id="sheet">'
    f << '<div class="object">'
    f << "<h1><a href=\"/v2/doc\">API</a>: #{name}</h1>"
    if obj['desc']
      f << "<div class=\"description\">#{hb obj['desc']}</div>"
    end

    # Attributes
    f << '<div class="attributes">'
    f << "<h2>Attributes</h2>"
    f << '<dl>'

    begin
      klass = API.const_get(name)
      attrs = obj['attrs'].keys.map{|e| e.to_sym} | klass.attrs
      attrs.sort {|a,b| a.to_s <=> b.to_s}.each do |attr|
        if desc = obj['attrs'][attr.to_s] and klass.attrs.include? attr
          f << "<dt>#{attr}</dt>"
          f << "<dd>#{hb desc}</dd>"
        elsif klass.attrs.include? attr
          puts "Undocumented attribute #{klass}.#{attr}"
        else
          puts "Documented but unspecified attribute #{klass}.#{attr}"
        end
      end
    rescue => e
      puts "Couldn't resolve class #{name}: #{e}"
      obj['attrs'].sort.each do |attr, desc|
        f << "<dt>#{attr}</dt>"
        f << "<dd>#{hb desc}</dd>"
      end
    end

    f << "</dl>"
    f << '<div class="clear"></div>'
    f << '</div>'

    f << '</div>'
    f << '</div>'
    f << "</body>"
    f << "</html>"
  end
end

d.each do |path|
  File.open("#{@out_dir}/paths/#{path_to_id(path['path'])}.html", 'w') do |f|
    f << File.read('doc/preamble.html')

    f << '<div id="sheet">'
    f << '<div class="path">'
    f << "<h1><a href=\"/v2/doc\">API</a>: #{h path['path']}</h1>"
    f << "<div class=\"description\">#{hb path['desc']}</div>"
    if path['params']
      f << '<div class="params">'
      f << "<h3>Parameters</h3>"
      f << '<dl>'
      path['params'].sort.each do |param, desc|
        f << "<dt>#{param}</dt>"
        f << "<dd>#{h desc}</dd>"
      end
      f << "</dl>"
      f << '<div class="clear"></div>'
      f << '</div>'
    end
    if path['attributes']
      f << '<div class="attributes">'
      f << "<h3>Attributes</h3>"
      f << '<dl>'
      path['attributes'].sort.each do |attr, desc|
        f << "<dt>#{attr}</dt>"
        f << "<dd>#{h desc}</dd>"
      end
      f << "</dl>"
      f << '<div class="clear"></div>'
      f << '</div>'
    end
    if path['example']
      # Example
      f << '<div class="example">'
      f << "<h3>Example</h3>"
      f << "<code>#{h path['example']}</code>"
      f << '</div>'
      # Response
      json = path['example_json'] || json(path['example'], :method => path['method'])
      xml = path['example_xml'] || xml(path['example'], :method => path['method'])
      f << "<table class=\"response\">"
      f << "<tr><th>XML</th><th>JSON</th></tr><tr>"
      f << "<td class=\"xml\"><code><pre>#{Rack::Utils.escape_html(xml)}</pre></code></td>"
      f << "<td class=\"json\"><code><pre>#{Rack::Utils.escape_html(json)}</pre></code></td>"
      f << "</tr></table>"
    end
    f << "</div>"
    f << "</div>"
    f << "</body>"
    f << "</html>"
  end
end
