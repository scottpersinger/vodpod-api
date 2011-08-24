#!/usr/bin/ruby

require 'rubygems'
require 'bacon'

require "#{File.dirname(__FILE__)}/../lib/vodpod-api"
require "api/adapter.rb"

module API
  describe 'The API adapter' do
    should 'find users' do
      users = API.users 'sort' => 'name'
      users.size.should == 10
      users.first.should.be.kind_of? User
      users[8].name.should == '    Bambang Sigit'
    end

    should 'accept symbolic keys' do
      user = API.user('aphyr', :include => 'tags')
      user.to_hash.should.include :tags
    end

    should 'accept arrays as well as comma-separated strings' do
      user = API.user('aphyr', :include => [:name, :description]).to_hash
      user.should.include? :name
      user.should.include? :description
    end
  end
end
