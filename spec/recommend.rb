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
  describe 'Recommending' do
    behaves_like :rack_test
    behaves_like :api

    should 'be able to recommend a video' do
      key = 3480943
      
      # Remove old vote.
      Vodpod::Vote.filter(
        :video_id => key,
        :user_id => API.user('aphyr').id
      ).destroy

      # Create vote
      r = json("/videos/#{key}")['recommends']
      json("/videos/#{key}/recommend",
        :method => :post,
        :auth_key => '5c91b8b53586434c'
      ).should.be.true

      # Confirm!
      API.cache.clear
      json("/videos/#{key}")['recommends'].should == r + 1
    end
    
    should 'be able to recommend a collection video' do
      key = 3480943
      
      # Remove old vote.
      Vodpod::Vote.filter(
        :video_id => key,
        :user_id => API.user('aphyr').id
      ).destroy

      # Create vote
      r = json("/users/aphyr/collections/aphyr/videos/#{key}")['recommends']
      json("/users/aphyr/collections/aphyr/videos/#{key}/recommend",
        :method => :post,
        :auth_key => '5c91b8b53586434c'
      ).should.be.true

      # Confirm!
      API.cache.clear
      json("/users/aphyr/collections/aphyr/videos/#{key}")['recommends'].should == r + 1
    end

    should 'not be able to recommend twice' do
      key = 3480943
      
      # Remove old vote.
      Vodpod::Vote.filter(
        :video_id => key,
        :user_id => API.user('aphyr').id
      ).destroy

      # Create vote
      json("/videos/#{key}/recommend",
        :method => :post,
        :auth_key => '5c91b8b53586434c'
      ).should.be.true
      json_error("/videos/#{key}/recommend",
        :method => :post,
        :auth_key => '5c91b8b53586434c'
      )['message'].should =~ /already recommended/
    end
  end
end
