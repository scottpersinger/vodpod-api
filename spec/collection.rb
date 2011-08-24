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
  describe '/users/<user>/collections' do
    behaves_like :rack_test
    behaves_like :api

    should 'list collections for a user' do
      json('/users/aphyr/collections') do |j|
        j = j['results']
        j.should.be.kind_of? Array
        j.first['key'].should == 'aphyr'
        j.first['name'].should == "aphyr's videos"
      end
    end

    should 'display a particular collection' do
      json('/users/spencer/collections/electro', :include => 'videos,key,name') do |j|
        j['videos'].should.be.kind_of? Array
        j['videos'].size.should > 2
        j['videos'].first['title'].should.not.be.blank
        j['key'].should == 'electro'
        j['name'].should == "Electronic Music Videos"
      end
    end

    should 'not display nonexistent collections' do
      json_error('/users/aphyr/collections/electro')['message'].should =~ /does not exist/
    end
   
    should 'filter collection information' do
      json('/users/aphyr/collections/aphyr', :include => 'key,videos') do |j|
        ['key', 'videos'].each do |attr|
          j.keys.should.include attr
        end
        j['videos'].should.be.kind_of Array
        j['videos'].size.should > 5
      end
    end

    should 'return collection information for all attributes' do
      Collection.attrs.each do |attr|
        json('/users/aphyr/collections/aphyr', :include => attr) do |j|
          j.should.include attr.to_s
        end
      end
    end

    should 'have a user' do
      json('/users/aphyr/collections/aphyr', :include => 'user') do |j|
        j['user']['key'].should == 'aphyr'
      end
    end

    should 'have videos' do
      json('/users/aphyr/collections/aphyr', :include => 'videos') do |j|
        j['videos'].size.should > 5
        j['videos'][0]['title'].should.not.be.blank
        j['videos'][0]['embed'].should =~ /http:\/\//
        j['videos'][0]['thumbnail'].should =~ /\.(jpg|gif)$/
      end
    end

    should 'have tags' do
      json('/users/spencer/collections/electro', :include => 'tags') do |j|
        j['tags'].size.should == API.config.include_tags_limit
        j['tags'].map{|t| t['key']}.should.include? 'french'
      end
    end

    should 'have a thumbnail' do
      json('/users/spencer/collections/electro', :include => 'thumbnail') do |j|
        j['thumbnail'].should =~ /^http:\/\/.+\.jpg$/
      end
    end

   should 'include counts for tags' do
      json('/users/aphyr/collections/aphyr', :include => 'tags') do |j|
        j['tags'].each do |t|
          t['count'].should.be.kind_of? Integer
        end
      end
    end
  end
end
