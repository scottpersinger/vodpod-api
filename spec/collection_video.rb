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
  describe '/users/<user>/collections/<collection>/videos' do
    behaves_like :rack_test
    behaves_like :api

    should 'list videos for a collection' do
      json('/users/aphyr/collections/aphyr/videos', :sort => :created_at) do |j|
        j['total'].should > 10
        j = j['results']
        j.should.be.kind_of? Array
        j.first['title'].should == "Official Neotokyo Trailer"
        j.first['key'].should == 1583973
        j.first['embed'].should.not.be.blank
        j.first['thumbnail'].should =~ /\.jpg$/
      end
    end

    should 'list videos with a tag' do
      json('/users/aphyr/collections/aphyr/videos', :tag => 'neotokyo', :include => 'tags') do |j|
        j['results'].each do |v|
          tags = v['tags'].map {|e| e['key']}
          (tags.include? 'neotokyo').should.be.true
        end
      end
    end

    should 'not list videos with any nonexistent tags' do
      json('/users/aphyr/collections/aphyr/videos', :tag => 'foobeezee', :include => 'tags')['total'].should == 0
    end

    should 'not list videos for nonexistent users/collections' do
      json_error('/users/asdfjsd039r23/collections/089u28jfa/videos')['message'].should =~ /not exist/
      json_error('/users/aphyr/collections/089u28jfa/videos')['message'].should =~ /not exist/
    end

    should 'sort by most popular' do
      json('/users/aphyr/collections/aphyr/videos', :sort => 'popular') do |j|
        #TODO: how do we test this?
        j['results'].first['total_views'].should > 5
      end
    end

    should 'sort by ranking' do
      json('/users/aphyr/collections/aphyr/videos', :sort => 'ranking', :include => 'ranking', :limit => 100) do |j|
        j['results'].each_with_index do |v, i|
          if succ = j['results'][i + 1] and v['ranking'] and succ['ranking']
            v['ranking'].should >= succ['ranking']
          end
        end
      end

      json('/users/aphyr/collections/aphyr/videos', :sort => 'ranking', :order => 'asc', :include => 'ranking') do |j|
        j['results'].each_with_index do |v, i|
          if succ = j['results'][i + 1] and v['ranking'] and succ['ranking']
            v['ranking'].should <= succ['ranking']
          end
        end
      end
    end

    should 'display a particular video' do
      json('/users/aphyr/collections/aphyr/videos/1767013', :include => 'tags,title,key') do |j|
        j['tags'].should.be.kind_of? Array
        j['tags'].map{|e| e['key']}.should == ['neotokyo', 'game', 'trailer']
        j['title'].should =~ /neotokyo recon demo/
        j['key'].should == 1767013
        j['url'].should =~ /u=aphyr/
        j['url'].should =~ /c=aphyr/
      end
    end

    should 'not display nonexistent videos' do
      json_error('/users/aphyr/collections/aphyr/videos/343')['message'].should =~ /does not exist/
    end
   
    should 'filter video information' do
      json('/users/aphyr/collections/aphyr/videos/278382', :include => 'key,title,tags') do |j|
        ['key', 'tags', 'title'].each do |attr|
          j.keys.should.include attr
        end
        j['key'].should == 278382
        j['title'].should == "Monty Python - Confuse-A-Cat"
        j['tags'].should.be.kind_of Array
        j['tags'].size.should == 2
      end
    end

    should 'return collection information for all attributes' do
      Collection.attrs.each do |attr|
        json('/users/aphyr/collections/aphyr', :include => attr) do |j|
          j.should.include attr.to_s
        end
      end
    end

    should 'have a user and collection' do
      json('/users/aphyr/collections/aphyr/videos/278382', :include => 'user,collection') do |j|
        j['collection']['key'].should == 'aphyr'
        j['user']['key'].should == 'aphyr'
      end
    end

    should 'have tags' do
      json('/users/aphyr/collections/aphyr/videos/278382', :include => 'tags') do |j|
        j['tags'].size.should > 1
        j['tags'].first['key'].should == 'cat'
      end
    end

    should 'have an embed tag' do
      json('/users/aphyr/collections/aphyr/videos/1869137') do |j|
        j['embed'].should =~ /(<embed)|(<object)|(<iframe)/
        j['embed'].should =~ /stats\.vodpod\.com/
        j['autoplay_embed'].should =~ /autoplay=1/
        j['autoplay_embed'].should =~ /stats\.vodpod\.com/
      end
    end

    should 'have comments' do
      json('/users/aphyr/collections/aphyr/videos/1869137', :include => 'comments') do |j|
        j['comments'].any? { |c| c['text'] =~ /6000/ }.should.be.true
      end
    end

    should 'have collection comments' do
      json('/users/aphyr/collections/aphyr/videos/1869137', :include => 'collection_comments') do |j|
        j['collection_comments'].first['created_at'].should.not.be.blank
        j['collection_comments'].first['text'].should.not.be.blank
      end
    end

    should 'have a description' do
      json('/users/aphyr/collections/aphyr/videos/1543249') do |j|
        j['description'].should =~ /^Wow\. I've watched some of the Zoobombers do stunts\-\-/
      end
    end
    
    should 'have collections_count greater than 0' do
      json('/users/aphyr/collections/aphyr/videos/1543249', :include => 'collections_count') do |j|
        j['collections_count'].should > 0
      end
    end

    should 'have video_host sub-record and return it by default' do
      json('/users/westindiangirl/collections/westindiangirl/videos/1445599') do |j|
        j['video_host'].should.not.be.blank
        j['video_host']['url'].should =~ /youtube\.com/
        j['video_host']['domain'].should =~ /you/
      end
    end
  end
end
