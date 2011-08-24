#!/usr/bin/ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/bacon'

require __DIR__('shared')
require __DIR__('../lib/vodpod-api')
Ramaze.options.roots = __DIR__('../')
API.init
API.start

describe 'Cross-site' do
  behaves_like :rack_test
  behaves_like :api

  should 'not allow access from arbitrary domains' do
    get('/.json').headers['Access-Control-Allow-Origin'].should.be.nil
    get('/.json', {}, {'Origin' => 'http://foo.bar'}).headers['Access-Control-Allow-Origin'].should.be.nil
  end

  ['http://localhost',
   'http://localhost:8000', 
   'http://localhost:123', 
   'http://vodpod.com'].each do |o|
    should "allow access from #{o}" do
      r = get('/.json', {}, {'HTTP_ORIGIN' => o})
      r.headers['Access-Control-Allow-Origin'].should == o
    end
  end
end
