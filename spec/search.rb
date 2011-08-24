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
  describe API::Searcher do
    should 'support several requests at once' do
      threads = []
#      STDOUT.sync = true
      50.times do |i|
        threads << Thread.new do
          sleep rand * 10
#          puts "Start search #{i}"
          API.search('cats', 'limit' => 1).data.first.title.should.not.be.empty
#          puts "Finish search #{i}"
        end
      end
      
      threads.each do |t|
        t.join
      end
    end
  end

  describe '/search' do
    behaves_like :rack_test
    behaves_like :api

    should 'not search if no query given' do |j|
      json_error '/search'
    end

    should 'search globally' do
      json('/search', :query => 'funny') do |j|
        j['results'].size.should > 2
        found = j['results'].any? do |v|
          v['description'] =~ /funny/i or 
          v['video_host']['description'] =~ /funny/i
        end
        found.should.be.true
      end
    end

    should 'search with included parameters' do
      json('/search', :query => 'awesome', :include => 'autoplay_embed') do |j|
        j['results'].size.should > 2
        j['results'][0]['autoplay_embed'].should.not.be.blank
      end
    end

    should 'search in collections' do
      json('/users/aphyr/collections/aphyr/search', :query => 'neotokyo') do |j|
        j['results'].size.should > 2
        found = j['results'].any? do |v|
          v['description'] =~ /neotokyo/i or 
          v['video_host']['description'] =~ /neotokyo/i
        end
        found.should.be.true
      end
    end

    should 'search for users' do
      json('/search/users', :query => 'gardening') do |j|
        j['total'].should > 5
        j['results'].size.should > 2
        j['results'][0]['name'].should.not.be.blank
        j['results'][0]['videos_count'].should.not.be.blank
      end
    end

    should 'paginate searches' do
      total = json('/search', :query => 'funny cat', :limit => 10)['results'].map{|e| e['title']}
      a = json('/search', :query => 'funny cat', :limit => 5)['results'].map{|e| e['title']}
      b = json('/search', :query => 'funny cat', :limit => 5, :page => 2)['results'].map{|e| e['title']}
      total.should == a + b
    end
  end
end
