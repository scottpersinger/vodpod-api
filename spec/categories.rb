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
  describe 'categories' do
    behaves_like :rack_test
    behaves_like :api

    should 'show a category in reasonable time' do
      json('/categories/music')
      under(0.2) do
        json('/categories/music')
      end
    end

    should 'list top-level categories' do
      c = json('/categories', :include => :all)
      c['total'].should == c['results'].size
      c['total'].should > 5
      c['results'].first['name'].should == 'Popular'
      c['results'].first['key'].should == 'popular'
#      c['results'].first['daily_count'].should >= 0
#      c['results'].first['total_count'].should >= c['results'].first['daily_count']
    end

    should 'show a category' do
      c = json '/categories/music', :include => :all
      c['name'].should == 'Music'
      c['key'].should == 'music'
      c['subcategories'].size.should > 4
      c['subcategories'].first['key'].should == 'pop'
    end

    should 'show a subcategory' do
      c = json '/categories/music/pop'
      c['name'].should == 'Pop'
    end

    should 'have a leaderboard of top users' do
      u = json('/categories/music/country')['top_users']
      u.should.be.kind_of Array
      u.size.should == 20
      u.first['key'].should.not.be.blank
      points = u.map { |user| user['points'] }
      points.should == points.sort.reverse
    end

    should 'have recommended users' do
      u = json('/categories/tech')['recommended_users']
      u.should.be.kind_of Array
      u.size.should > 20
      u.first['key'].should.not.be.blank
      
      #u = json('/categories/popular')['recommended_users']
      #u.should.be.kind_of Array
      #u.size.should > 20
      #u.first['key'].should.not.be.blank
    end
  end
end
