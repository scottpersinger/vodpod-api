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

  should 'return an error without an API key' do
    get('/.json').status.should == 403
    # Rack bug? Returns text/plain
#    last_response['Content-Type'].should == 'application/json'
    j = JSON.parse(last_response.body)
    j[0].should.be.false
    j[1]['message'].should == "no API key provided"
  end

  should 'return an error with an invalid API key' do
    get('/.json?api_key=foo').status.should == 403
#    last_response['Content-type'].should == 'application/json'
    j = JSON.parse(last_response.body)
    j[0].should.be.false
    j[1]['message'].should == "invalid API key"
  end

  should 'return XML for .xml errors' do
    should.not.raise(LibXML::XML::Error) do
      LibXML::XML::Parser.string(get('/.xml').body).parse
    end
  end

  should 'return JSON for .json errors' do
    should.not.raise(JSON::ParserError) do
      JSON.parse(get('/.json').body)
    end
  end
  
  should 'return identical responses for .js and .json' do
    get('/.json').body.should == get('/.js').body
  end
end
