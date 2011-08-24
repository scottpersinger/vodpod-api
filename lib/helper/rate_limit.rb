module Ramaze
  module Helper
    module RateLimit
      INTERVAL = 3600
      REMAINING = 1000

      # This implementation is subject to cache exhaustion; we should use Redis
      # or some other higher-persistence high-performance store. Mysql is
      # probably too slow.
      #
      # Limit is an array
      # [reset_time, remaining]
      def rate_limit
        return nil unless @client

        t = Time.now
        limit = API.cache["rate_limits/users/#{@client.key}"]
        if limit.nil? or limit[0] <= t.to_i
          # Reset limit
          limit = [t.to_i + INTERVAL, REMAINING]
        end

        # Update limit
        limit[1] = limit[1] - 1

        if limit[1] <= 0
          # Limit exceeded
          raise API::RateLimitError, "rate limit exceeded (#{REMAINING}/#{INTERVAL} seconds)"
        end

        # Store limit
        API.cache.store("rate_limits/users/#{@client.key}", limit, :ttl => limit[0] - t.to_i)
        
        # Set rate limit headers
        response['X-RateLimit-Limit'] = REMAINING.to_s
        response['X-RateLimit-Remaining'] = limit[1].to_s
        response['X-RateLimit-Reset'] = Time.at(limit[0]).xmlschema

        true
      end
    end
  end
end
