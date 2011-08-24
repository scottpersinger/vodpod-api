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
  describe '/login' do
    behaves_like :rack_test
    behaves_like :api

    should 'not accept invalid logins' do
      json_error '/login', :username => 'foo', :password => 'bar'
      json_error '/me', :api_key => nil
    end

    should 'issue an auth cookie after login' do
      j = json '/login', :username => 'aphyr', :password => 'CliWrific7'
      j.should.be.true
    end

    should 'accept subsequent requests without an API key' do
      j = json '/me', :api_key => nil
      j['key'].should == 'aphyr'
    end

    should 'return a user with api_key and auth_key for login with return_user' do
      j = json '/login', :username => 'kyletest', :password => 'kyletest', :return_user => true
      j['key'].should == 'kyletest'
      j['api_key'].should.not.be.blank
      j['auth_key'].should.not.be.blank
    end

    should 'logout' do
      j = json '/logout'
      j.should.be.true
      json_error '/me', :api_key => nil
    end
  end
end
