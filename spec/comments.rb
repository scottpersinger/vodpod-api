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
  describe '/videos/<video>/comments' do
    behaves_like :rack_test
    behaves_like :api

    should 'show comments on a video' do
      json('/videos/118831/comments') do |j|
        j['total'].should > 4
        j = j['results']
        j.should.be.kind_of? Array
        Numeric.should === j[0]['key']
        j.any?{|c| c['text'] =~ /fun/i}.should.be.true
        j.any?{|c| c['user']['thumbnail'] =~ /s3\.vpimg\.net\/vodpod\.com\.users\.image\/\d+\.medium\.jpg/}.should.be.true
      end

      xml('/videos/118831/comments')
    end

    should 'show collection comments on a video' do
      json('/users/spencer/collection/videos/118831/comments') do |j|
        j['total'].should >= 1
        j = j['results']
        j.should.be.kind_of? Array
        j.any?{|c| c['text'] =~ /fun/i}.should.be.true
        j.any?{|c| c['user']['thumbnail'] =~ /s3\.vpimg\.net\/vodpod\.com\.users\.image\/\d+\.medium\.jpg/}.should.be.true
      end
    end

    should 'paginate comments' do
      a = json('/videos/118831/comments', :limit => 3)
      b = json('/videos/118831/comments', :limit => 3, :page => 2)
      a['total'].should == b['total']
      a['results'].size.should == 3
      b['results'].size.should.not.be.zero
      (a['results'] & b['results']).should.be.empty
    end

    should 'have guest users' do
      json('/users/spencer/collections/spencerpod/videos/2723383/collection_comments') do |j|
        j['results'][0]['user']['name'].should == 'myra'
        j['results'][0]['user']['key'].should == 'guest'
        j['results'][0]['text'].should =~ /reflection from a mirror/
      end
    end

    should 'be able to comment on a video' do
      text = "The time is #{Time.now.to_s}"
      key = 3480943
      j = json("/videos/#{key}/comments/new",
        :method => :post,
        :text => text,
        :auth_key => '5c91b8b53586434c'
      )

      j['text'].should == text
      j['key'].should.not.be.blank
      j['user']['key'].should == 'aphyr'
      j['user']['name'].should == 'aphyr'

      # Check that the comment list includes our comment
      saved = json("/videos/#{key}/comments", :limit => 1)['results'].first
      saved.should == j
    end
  end

  describe '/user/<user>/collections/<collections>/videos/<video/comments' do
    behaves_like :rack_test
    behaves_like :api

    should 'be able to comment on a video' do
      text = "The time is #{Time.now.to_s}"
      key = 3281916
      j = json("/users/pkulak/collections/pkulak/videos/#{key}/comments/new",
        :method => :post,
        :text => text,
        :auth_key => '5c91b8b53586434c'
      )

      j['text'].should == text
      j['key'].should.not.be.blank
      j['user']['key'].should == 'aphyr'
      j['user']['name'].should == 'aphyr'

      # Check that the comment list includes our comment
      saved = json("/videos/#{key}/comments", :limit => 1)['results'].first
      saved.should == j
    end
  end

  describe 'CollectionVideo comments' do
    behaves_like :rack_test
    behaves_like :api

#    should 'not be able to comment without POST' do
#      json_error('/users/aphyr/collections/aphyr/videos/2901977/collection_comments/new',
#        :text => 'Test comment', 
#        :user => {:name => 'API Tester', :email => 'api@vodpod.com'}, 
#        :auth_key => '5c91b8b53586434c'
#      )['message'].should =~ /POST required/
#    end

    should 'not be able to comment without an auth key' do
      json_error('/users/aphyr/collections/aphyr/videos/2901977/collection_comments/new',
        :text => 'Test comment', 
        :user => {:name => 'API Tester', :email => 'api@vodpod.com'},
        :method => :post
      )['message'].should =~ /auth_key.+required/
    end
    
    should 'not be able to collection_comment on other users collections' do
      json_error('/users/spencer/collections/spencerpod/videos/2723383/collection_comments/new',
        :text => 'Test comment', 
        :user => {:name => 'API Tester', :email => 'api@vodpod.com'},
        :method => :post,
        :auth_key => '5c91b8b53586434c'
      )['message'].should =~ /can't comment on another user's collection/
    end

    should 'be able to collection_comment on a collectionvideo.' do
      j = json('/users/aphyr/collections/aphyr/videos/839431/collection_comments/new',
        :text => 'Test comment', 
        :user => {:name => 'API Tester', :email => 'api@vodpod.com'}, 
        :auth_key => '5c91b8b53586434c', 
        :method => :post
      )
      j['text'].should == 'Test comment'
      j['key'].should.not.be.blank
      j['user']['key'].should == 'guest'
      j['user']['name'].should == 'API Tester'

      # Check that the collection comments list includes our comment.
      saved = json('/users/aphyr/collections/aphyr/videos/839431/collection_comments')['results'].first

      saved.should == j
    end

    should 'be able to delete a collection video comment' do
      key = json('/users/aphyr/collections/aphyr/videos/839431/collection_comments')['results'].first['key']
      j = json("/users/aphyr/collections/aphyr/videos/839431/collection_comments/#{key}/delete", :auth_key => '5c91b8b53586434c', :method => 'post')
      j.should.be.true
    end
  end
end
