class API::MainController
  # Delete a collection comment
  h 'users', :*, 'collections', :*, 'videos', :*, 'collection_comments', :*, 'delete' do |user_key, collection_key, video_key, comment_key|
    require_write_auth

#    unless request.post?
#      raise API::Error, 'HTTP POST required'
#    end

    # Get comment/collection
    unless comment = Vodpod::CollectionVideoComment[:id => comment_key]
      raise API::Error, "Comment (#{comment_key}) does not exist"
    end
    collection = comment.collection

    unless comment.user_id == @client.id or collection.user_id == @client.id
      raise API::Error, "Can't delete another user's comments"
    end

    if comment.destroy
      true
    else
      raise API::Error, "An error occurred trying to delete your comment"
    end
  end
end
