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
  describe 'Caching' do
    behaves_like :rack_test
    behaves_like :api

    def time
      t1 = Time.now
      yield
      t2 = Time.now
      t2 - t1
    end

    should 'be hella fast on the second search request' do
      API.cache.clear
      times = (0..5).map do
        time do
          json('/users/aphyr/feed', :include => 'all')
        end
      end

      average = times[1..-1].inject { |i, sum| i + sum } / (times.size - 1)
      average.should < times.first
    end
  end
end
