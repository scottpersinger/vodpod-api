#!/usr/bin/ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/bacon'
require 'sequel/extensions/blank'

require __DIR__('shared')
require __DIR__('../lib/vodpod-api')
Ramaze.options.roots = __DIR__('../')
API.init
API.start

module API
  describe '/users' do
    behaves_like :rack_test
    behaves_like :api

    should 'show ratelimit information' do
      j = json '/rate_limits'
      j['limit'].should == Ramaze::Helper::RateLimit::REMAINING 
      j['interval'].should == Ramaze::Helper::RateLimit::INTERVAL
      Time.parse(j['reset']).should >= Time.now
      j['remaining'].should > 0
      j['remaining'].should <= j['limit']
    end
  end
end
