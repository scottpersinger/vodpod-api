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
  describe '/users' do
    behaves_like :rack_test
    behaves_like :api

    should 'not allow listing of users' do
      json_error('/users')
    end

#    User.attr_strings.sort.each do |attr|
#      it "#{attr} should be fast" do
#        j = json_plain('/users/aphyr', :include => attr)
#        j[0].should.be.true
#      end
#    end

    should 'return all attributes when asked' do
      json('/users/aphyr', :include => 'all') do |j|
        j.keys.sort.should == User.attr_strings.sort
      end
    end

    should 'return information about specified attributes' do
      json('/users/aphyr', :include => 'tags,key') do |j|
        ['key', 'tags'].each do |attr|
          j.keys.should.include attr
        end
      end
    end

    should 'not return unlimited associations' do
      json('/users/spencer', :include => 'tags') do |j|
        j['tags'].size.should <= API.config.include_tags_limit
      end
    end

    should 'display an error when attempting to include bad attributes' do
      json_error('/users/aphyr', :include => 'tags, key,bar') do |j|
        j['message'].should =~ /invalid attribute/
      end
    end

    should 'return an error when invalid filter options are passed' do
      json_error('/users/aphyr', :include => 'tags', :whee => 'zoom', :yarr => 'foo') do |j|
        j['message'].should =~ /unknown parameters/
      end
    end

    should 'return information about a user' do
      json('/users/spencer', :include => 'key,description,collection,collections,tags') do |j|
        j['key'].should == 'spencer'
        j['description'].should =~ /Vodpod engineer/
        j['collections'].size.should > 2
        j['collection']['key'].should == 'spencerpod'
        j['tags'].find { |t| t['key'] == 'funny' }.should.not.be.nil
      end
    end

    should 'fail to display nonexistent users' do
      json_error('/users/dsfkjhasdfkhoh')['message'].should =~ /does not exist/
    end

    should 'return user information for all attributes' do
      User.attrs.each do |attr|
        json('/users/aphyr', :include => attr) do |j|
          j.should.include attr.to_s
        end
      end
    end

    should 'have videos' do
      json('/users/aphyr', :include => 'videos,videos_count') do |j|
        j['videos'].should.not.be.empty
        j['videos'].first['embed'].should.not.be.blank
        j['videos_count'].should > 5
      end
    end

    should 'have followers' do
      json('/users/aphyr', :include => 'followers,followers_count') do |j|
        j['followers_count'].should > 0
        j['followers'].size.should > 0
        if j['followers'].size != j['followers_count']
          at_exit do
            puts "\nJust so you know, followers_count (#{j['followers_count']}) and followers (#{j['followers'].size}) are out of sync for user #{j['key']}."
          end
        end
      end
    end

    should 'include counts for tags' do
      json('/users/aphyr', :include => 'tags') do |j|
        j['tags'].each do |t|
          t['count'].should.be.kind_of? Integer
        end
      end
    end

    should 'create new users' do
      username = "vodpodtest#{rand(10000)}"
      j = json('/users/new', :key => username, :password => 'vodpodtest1', :email => username + '@vodpod.com', :method => :post)
      j['name'].should == username
      j['videos_count'].should == 0
      key = j['key']
      j['key'].should =~ /^#{username}/
   
      j = json("/users/#{key}", :include => 'all')
      j['collections_count'].should == 1
      j['collections'][0]['name'].should.not.be.blank
      j['collections'][0]['key'].should.not.be.blank
      User[:simple_name => username].destroy
    end

    should 'not create new users with missing values' do
      username = "vodpodtest#{rand(10000)}"
      json_error('/users/new', :method => :post, :key => username, :password => 'vodpodtest1')['message'].should == 'missing parameter: email'
      json_error('/users/new', :method => :post, :email => "#{username}@vodpod.com", :password => 'vodpodtest1')['message'].should == 'missing parameter: key'
      json_error('/users/new', :method => :post, :email => "#{username}@vodpod.com", :key => username)['message'].should == 'missing parameter: password'
    end

    should 'not create new users with existing usernames or emails' do
      json_error('/users/new', :method => :post, :key => 'aphyr', :password => 'vodpodtest1', :email => 'vodpodtestsf83u423rd@vodpod.com')['message'].should =~ /name aphyr is already taken/
      username = "vodpodtest#{rand(10000)}"
      json_error('/users/new', :method => :post, :key => username, :password => 'vodpodtest1', :email => 'aphyr@aphyr.com')['message'].should =~ /email is already taken/
    end

    should 'update feed_checked_at' do
      t1 = json('/me')['feed_checked_at']
      json('/my/feed_checked', :auth_key => '5c91b8b53586434c').should == true
      API.cache.clear
      t2 = json('/me')['feed_checked_at']
      t1.should.not == t2
    end
  end
end
