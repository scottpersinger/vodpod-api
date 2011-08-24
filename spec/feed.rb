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
  describe '/my/feed' do
    behaves_like :rack_test
    behaves_like :api

    should 'not show the feed for a nonexistent user' do
      json_error('/user/spencer/feed')
    end

    should 'not show the feed for another user' do
      json_error('/user/ssdiufh8939823fsd/feed')
    end

    should 'show your feed' do
      feed = json('/my/feed', :limit => 100)
      feed['results'].length.should > 1
      feed['results'].length.should < feed['total']
      feed['total'].should.not.be.zero
    
      items = feed['results']
      items.any? { |item|
        item['action'] == 'add_video'
      }.should.be.true
      items.any? { |item|
        next unless item['video']
        item['video']['embed'] =~ /<embed/
      }.should.be.true
    end

    should 'have a special filter for ios' do
      feed = json('/my/feed', :limit => 10, :filter => 'ios')['results']
      feed.should.be.kind_of Array
      feed.should.not.be.empty
      feed.first.should.be.kind_of Hash
      feed.first['key'].should.be.kind_of Integer
    end
  end
end
