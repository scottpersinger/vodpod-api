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
  describe '/videos' do
    behaves_like :rack_test
    behaves_like :api

    should 'not allow listing of videos without tags' do
      json_error('/videos')['message'].should =~ /belonging to specific tags/
    end

    should 'show a list of videos for a tag' do
      json('/videos', :tags => 'funny') do |j|
        j['total'].should > 10
        j = j['results']
        j.should.be.kind_of? Array
        j.first['key'].should.be.kind_of? Integer
        j.first['key'].should > 100
        j.first['title'].should.be.kind_of? String
        j.first['title'].should.not.be.blank
      end

      xml('/videos', :tags => 'funny')
    end

    should 'not show videos for any nonexistent tags' do
      json('/videos', :tags => 'fhsf98r2u3777f00DSFHDljjdjs')['total'].should == 0
    end
    
    should 'have an embed tag' do
      json('/videos/1342323') do |j|
        j['embed'].should =~ /(<embed)|(<object)|(<iframe)/
        j['embed'].should =~ /stats\.vodpod\.com/
        j['autoplay_embed'].should =~ /autoplay=1/
        j['autoplay_embed'].should =~ /stats\.vodpod\.com/
      end
    end

    should 'have comments' do
      json('/videos/1548742', :include => 'comments') do |j|
        j['comments'].size.should > 5
        j['comments'].first['text'].should.not.be.blank
        j['comments'].first['user']['key'].should.not.be.blank
      end
      
      json('/videos/19517', :include => 'comments') do |j|
        j['comments'].first['user'].should.not.be.blank
      end
    end

    should 'display a particular video' do
      json('/videos/1342323') do |j|
        j['key'].should == 1342323
        j['title'].should == 'Power Ranger Turbo The Movie 2/10'
        j['embed'].should =~ /http:\/\//
      end
    end

    should 'not display nonexistent videos' do
      json_error('/videos/electro')['message'].should =~ /does not exist/
      json_error('/videos/-1')['message'].should =~ /does not exist/
      json_error('/videos/23053045208502983570')['message'].should =~ /does not exist/
    end
   
    should 'filter video information' do
      json('/videos/1342733', :include => 'key,tags,title,users') do |j|
        ['key', 'tags', 'title', 'users'].each do |attr|
          j.keys.should.include attr
        end
        j['key'].should == 1342733
        j['tags'].map {|e| e['key']}.should == ["rock", "entertainment", "shr", "firewareosba", "mother", "schoolhouse", "essra", "mowhawk"]
        j['title'].should == "School house Rock - Mother Necessity"
        j['users'].map{|e| e['key']}.should.include? "dickenslmc"
        j['users'].map{|e| e['key']}.should.include? "arthjulia"
        j['users'].map{|e| e['key']}.should.include? "doku69"
      end
    end
    
    should 'have collections_count greater than 0' do
      json('/videos/1342323', :include => 'collections_count') do |j|
        j['collections_count'].should > 0
      end
    end
    
    should "return video_host_record row as video_host hash and have it by default" do
      json('/videos/1445599') do |j|
        j['video_host'].should.not.be.blank
        j['video_host']['description'].should.not.be.blank
        j['video_host']['domain'].should =~ /youtube\.com/
        j['video_host']['url'].should =~ /youtube\.com/
      end
    end

    should "include all attributes" do
      json('/videos', :include => :all, :tags => 'funny') do |j|
        j['total'].should > 100
        Video.attrs.each do |attr|
          j['results'].first.should.include? attr.to_s
        end
      end
    end
  end
end
