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
  describe 'Collecting videos' do
    behaves_like :rack_test
    behaves_like :api

    should 'collect an existing video with new data' do
      key = 3432529
      
      # Delete previously collected version
      API.user('aphyr').collections.first.collection_videos_dataset.filter(:video_id => key).destroy
      
      # Collect!
      v = json("/my/videos/new",
        :method => :post,
        :title => "My recollected video",
        :key => key,
        :auth_key => '5c91b8b53586434c',
        :tags => 'test,android,api',
        :description => "Test video from #{Time.now}"
      )

      key.should == v['key']
      v['title'].should == "My recollected video"
      
      # Check that my collection includes the video
      API.cache.clear
      v = json('/my/videos', :include => 'tags')['results'].first
      v['key'].should == key
      v['title'].should == "My recollected video"
      v['embed'].should =~ /embed|object|iframe/
      v['description'].should.not.be.blank
      v['tags'].any? { |t| t['key'] == 'android' }.should.be.true
      v['tags'].any? { |t| t['key'] == 'test' }.should.be.true
      v['created_at'].should.not.be.blank
    end

    should 'collect a video with no new data' do
      key = 3432529
      
      o = json("/videos/#{key}")
      
      # Delete previously collected version
      API.user('aphyr').collections.first.collection_videos_dataset.filter(:video_id => key).destroy
      
      # Collect!
      v = json("/my/videos/new",
        :method => :post,
        :key => key,
        :auth_key => '5c91b8b53586434c'
      )

      v['key'].should == o['key']
      v['title'].should == o['title']
      v['embed'].sub(/http:\/\/stats\.vodpod\.com.*/, '').should == 
      o['embed'].sub(/http:\/\/stats\.vodpod\.com.*/, '')
      
      # Check that my collection includes the video
      API.cache.clear
      v = json('/my/videos', :include => 'tags')['results'].first
      v['key'].should == key
      v['embed'].should =~ /embed|object|iframe/
      v['description'].should.not.be.blank
      v['created_at'].should.not.be.blank
      #TODO: Hmm, maybe this should happen.
      # v['tags'].should == []
    end

    should 'require either media or a video key' do
      key = 3432529
      json_error("/my/videos/new",
        :method => :post,
        :title => "My recollected video",
        :auth_key => '5c91b8b53586434c',
        :tags => 'test,android,api',
        :description => "Test video from #{Time.now}"
      )
    end 

    should 'require auth' do
      key = 3432529,
      json_error("/my/videos/new",
        :method => :post,
        :title => "My recollected video",
        :key => key,
        :tags => 'test,android,api',
        :description => "Test video from #{Time.now}"
      )['message'].should =~ /auth/i
    end
  end
end
