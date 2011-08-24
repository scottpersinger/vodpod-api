#!/usr/bin/ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/bacon'

require __DIR__('shared')
require __DIR__('../lib/vodpod-api')
Ramaze.options.roots = __DIR__('../')
API.init
API.start

describe 'The error handler' do
  behaves_like :rack_test
  behaves_like :api

  should 'return JSONP if .jsonp?callback= given' do
    get('/me.jsonp?callback=myCall_back&api_key=123456').body.should ==
      'myCall_back(' + get('/me.json?api_key=123456').body + ')'
  end

  should 'not accept evil callbacks' do
    get('/me.jsonp?callback=foo();%20bar&api_key=123456').body.should =~ /error/i
    get('/me.jsonp?callback=document.write&api_key=123456').body.should =~ /error/i
  end

  should 'not accept blank callbacks' do
    get('/me.jsonp?api_key=123456').body.should =~ /error/i
  end

  should 'return jsonp on errors' do
    a = get('/search.jsonp', :callback => 'foo', :api_key => '123456')
    b = get('/search.json', :api_key => 123456)
    a.status.should == 200
    a.status.should.not == b.status

    a = a.body.gsub(/jsonp\.rb\:\d+/,'')
    b = "foo(#{b.body.gsub(/jsonp\.rb\:\d+/,'')})"

    a.should == b
  end

  should 'not accept cookie authentication' do
    json('/login', :username => 'kyletest', :password => 'kyletest', :api_key => nil)
    get('/me.jsonp', :callback => 'j', :api_key => nil).body.should =~ /no API key provided/
    json('/logout')
  end
end
