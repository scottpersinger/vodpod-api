module Ramaze::Helper::Pagination
  # Takes a hash with :limit, :per_page, :offset, :page arguments, and returns
  # :limit, :offset.
  def pagination_options(request)
    limit = (request[:limit] or request[:per_page] or 32).to_i

    offset = if request[:offset]
      request[:offset].to_i
    elsif request[:page]
      (request[:page].to_i - 1) * limit
    else
      0
    end
    error "offset must be positive" if offset < 0

    {:limit => limit, :offset => offset}
  end
end
