class API::MainController
  # Update the feed_checked_at for a user.
  h 'users', :*, 'feed_checked' do |user_key|
    require_write_auth

    unless u = API.user(user_key) and u === @client
      raise API::Error, "cannot update another user's feed_checked_at"
    end

    if request[:at]
      begin
        time = DateTime.parse(request[:at]).to_time
      rescue
        raise API::Error, "invalid date"
      end
      if time > Time.now
        if time - Time.now < 60
          # We'll allow a minute of clock desync
          time = Time.now
        else
          raise API::Error, "you're from the future, aren't you?"
        end
      end
    else
      time = Time.now
    end

    if u.feed_checked_at.nil? or time > u.feed_checked_at
      u.feed_checked_at = time
      u.save_changes :validate => false
    end

    true
  end
end
