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
  describe '/my shortcuts' do
    behaves_like :rack_test
    behaves_like :api

    it 'maps /me' do
      json('/me').should == json('/users/aphyr')
    end
    
    it 'maps /my/videos' do
      json('/my/videos').should == json('/users/aphyr/videos')
    end

    it 'maps /my/videos/<video>' do
      json('/my/videos/1543249').should == json('/users/aphyr/videos/1543249')
    end

    it 'maps /my/collections' do
      json('/my/collections').should == json('/users/aphyr/collections')
    end

    it 'maps /my/collection' do
      a = json('/my/collection')
      b = json('/users/aphyr/collection')
      c = json('/users/aphyr/collections/aphyr')
      a.should == b
      b.should == c
    end

    it 'maps /my/collection/videos' do
      json('/my/collection/videos').should == json('/users/aphyr/collection/videos')
    end

    it 'maps /my/search' do
      json('/my/search', :query => 'funny').should == json('/users/aphyr/search', :query => 'funny')
    end
  end
end
