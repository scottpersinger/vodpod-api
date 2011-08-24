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

Vodpod.config.starling = :noop

def upload_error(opts = {})
  opts[:media] = Rack::Test::UploadedFile.new(opts[:media], "video/mp4") if opts[:media]
  json = JSON.parse(post("/my/videos/new", opts).body)

  json[0].should == false
  json[1]
end

def upload(opts = {})
  opts[:media] = Rack::Test::UploadedFile.new(opts[:media], "video/mp4")
  json = JSON.parse(post("/my/videos/new", opts).body)
  
  if json[0].false?
    raise RuntimeError.new("Error: #{json[1]["message"]}")
  end

  json[1]
end

module API
  describe 'Video uploading' do
    behaves_like :rack_test
    behaves_like :api

    should 'upload a video' do
      file = File.expand_path(__DIR__('../data/droid.mp4'))
      File.stat(file).size.should.not.be.zero
      
      v = upload :title => "Droid video",
        :media => file,
        :api_key => '5c87948ac1979401',
        :auth_key => '5c91b8b53586434c',
        :tags => 'test,android,api',
        :description => "Test video from #{Time.now}"

      key = v['key']
      v['title'].should == "Droid video"
      
      # Check to ensure that the video was uploaded.
      d = (Net::HTTP.get(URI.parse(v['media'])).size - File.stat(file).size).abs
      d.should < 1000

      # Check that my collection includes the video
      v = json('/my/videos', :include => :tags)['results'].first
      v['key'].should == key
      v['description'].should.not.be.blank
      v['tags'].any? { |t| t['key'] == 'android' }.should.be.true
      v['tags'].any? { |t| t['key'] == 'test' }.should.be.true
      v['created_at'].should.not.be.blank
    end

    should 'require auth' do
      upload_error(
        :title => "Droid video",
        :api_key => '5c87948ac1979401'
      )['message'].should =~ /auth/i
    end

#    should 'only accept POST' do
#      json_error('/my/videos/new',
#                :api_key => '5c87948ac1979401',
#                :auth_key => '5c91b8b53586434c'
#      )['message'].should =~ /post/i
#    end
  end
end
