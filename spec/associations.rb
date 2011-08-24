#!/usr/bin/ruby

require 'rubygems'
require 'ramaze'
require 'ramaze/spec/bacon'

require __DIR__('shared')
require __DIR__('../lib/vodpod-api')
Ramaze.options.roots = __DIR__('../')
API.init
API.start

module API
  describe 'Collections' do
    behaves_like :rack_test
    behaves_like :api

    should 'have tags' do
      tags = Collection.belonging_to('aphyr').api_get('aphyr').first.tags.map(&:name)
      tags.should.include "funny"
      tags.should.include 'trailer'
      tags.should.include "music"
    end

    it 'has a count of associated tags' do
      API.collection('spencer', 'spencerpod').tags_count.should > 10
    end
  end

  describe "CollectionVideo" do
    should 'have a collection' do
      CollectionVideo[3471097].collection.key.should == 'aphyr'
    end

    should 'have comments' do
      video = CollectionVideo[130640]
      c_comments = CollectionVideo[130640].collection_comments_dataset.unlimited.all
      comments = CollectionVideo[130640].comments_dataset.unlimited.all
      c_comments.size.should < comments.size
      c_comments.size.should > 0
      
      video.comments_count.should == comments.size
      video.collection_comments_count.should == c_comments.size
    end

    should 'eager-load comments' do
      c = CollectionVideo.filter(:id => 130640).eager(:comments).all.first
      c.associations.should.include :comments
      c.associations[:comments].should == c.comments
      c.comments.size.should > 4
      c.comments.find { |c| c.text =~ /fun/i }.should.not.be.nil
    end

    should 'have a user' do
      CollectionVideo[3471097].user.key.should == 'aphyr'
    end

    should 'have tags' do
      CollectionVideo[3471097].tags_dataset.map(:name).sort.should == ['republidance', 'tom delay']
    end
  end

  describe 'Comments' do
    should 'have users' do
      Comment.first.user.should.be.kind_of? User
    end

    should 'always eager-load users when eager loaded' do
      video = CollectionVideo.filter(:id => 130640).eager(:comments => :user).all.first
      comments = video.associations[:comments]
      comments.should.be.kind_of? Array
      comments.first.should.be.kind_of? Comment
      user = comments.first.associations[:user]
      user.should.be.kind_of? User
      user.name.should.not.be.blank
    end

    should 'not include queued comments in :moderated' do
      comment = Comment.order(:created_at.desc).first
      # Insert queued comment record
      if API.db[:comment_queues].filter(:group_audit_id => comment.id).count == 0
        qtime = Time.now
        API.db[:comment_queues] << {
          :group_audit_id => comment.id,
          :created_at => qtime
        }
      end

      # Check to ensure the comment does not appear in moderated subsets.
      Comment.filter(:id => comment.id).moderated.qualify.count.should == 0

      # Delete the queued entry
      API.db[:comment_queues].filter(:group_audit_id => comment.id).delete

      # Ensure comment is now moderated
      Comment.filter(:id => comment.id).moderated.qualify.count.should > 0
    end
  end

  describe "Users" do
    should 'have tags' do
      tags = User[:simple_name => 'aphyr'].tags.map {|e| e.key}
      tags.size.should > 5
      tags.should.include 'funny'
      tags.should.include 'trailer'
      tags.should.include 'music'
      tags.should.not.include ''
    end
  end

  describe "Tags" do
    should 'have collections' do
      collections = Tag[:name => 'zardoz'].collections.map{|e| e.subdomain}
      collections.size.should > 3 
      collections.should.include 'aphyr'
    end

    should 'have users' do
      users = Tag[:name => 'neotokyo'].users.map {|e| e.name}
      users.size.should > 1
      users.should.include 'aphyr'
    end

    should 'have videos' do
      v = Tag[:name => 'neotokyo'].videos
      v.size.should > 1
    end

    should 'have collection videos' do
      v = Tag[:name => 'neotokyo'].collection_videos
      v.size.should > 1
    end
  end

  describe 'Videos' do
    before do
      @video = Video[1441333]
    end

    should 'have collection videos' do
      @video.collection_videos.size.should > 1 
      @video.collection_videos.first.id.should == 2232531
    end

    should 'have a count of collection videos' do
      API.video(1548742).collection_videos_count.should > 10
    end

    should 'have collections' do
      @video.collections_dataset.map(:name).size.should > 1
      @video.collections_dataset.map(:name).should.include "aphyr's videos"
    end

    should 'have users' do
      users = @video.users.map { |e| e.key }
      users.size.should > 1
      users.should.include "aphyr"
    end

    should 'have tags' do
      tags = Video[1543249].tags.map { |e| e.key }
      tags.should.include 'crazy'
      tags.should.include 'stunts'
      tags.should.include 'wow'
    end
  end
end
