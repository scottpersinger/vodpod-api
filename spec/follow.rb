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
  describe 'Following' do
    behaves_like :rack_test
    behaves_like :api

    should 'follow a user' do
      user = 'pkulak'
      API.user('aphyr').unfollow(API.user(user))
      
      # Are we currently following?
      json_error("/my/following/#{user}")['message'].should =~ /not following user/
     
      # Follow 
      json("/my/following/new", :key => user, :auth_key => '5c91b8b53586434c').should.be.true
      
      # Check that our following set includes the user.
      json("/my/following/#{user}")['key'].should == user
      json('/my/following')['results'].any? { |u| u['key'] == user }.should.be.true
    end

    should 'unfollow a user' do
      user = 'pkulak'
      json("/my/following/#{user}/delete", :auth_key => '5c91b8b53586434c').should.be.true
      
      # Check that our following set does not include the user.
      API.cache.clear
      json_error("/my/following/#{user}")['message'].should =~ /not following user/
      json('/my/following')['results'].any? { |u| u['key'] == user }.should.be.false
    end

    should 'return error on double follow/unfollow' do
      user = 'pkulak'
      API.user('aphyr').unfollow(API.user(user))
      json("/my/following/new", :key => user, :auth_key => '5c91b8b53586434c').should.be.true
      json_error("/my/following/new", :key => user, :auth_key => '5c91b8b53586434c')['message'].should =~ /already following/
    end

    should 'not be able to follow without auth' do
      json_error("/my/following/new", :key => 'pkulak')['message'].should =~ /auth/
    end

    should 'not be able to follow for another user' do
      json_error("/users/markh/following/new", :key => 'pkulak', :auth_key => '5c91b8b53586434c')['message'].should =~ /behalf of another user/
      json_error("/users/sdafhkl/following/new", :key => 'pkulak', :auth_key => '5c91b8b53586434c').should['message'] =~ /behalf of another user/
    end

    should 'not be able to follow oneself' do
      json_error("/my/following/new", :key => 'aphyr', :auth_key => '5c91b8b53586434c')['message'].should =~ /can't follow yourself/
    end

    should 'not be able to follow a nonexistent user' do
      json_error("/my/following/new", :key => 'uf9wp8hqar9hw73hsd780f3', :auth_key => '5c91b8b53586434c')['message'].should =~ /does not exist/
      json_error("/my/following/new", :auth_key => '5c91b8b53586434c')['message'].should =~ /does not exist/
    end
  end
end
