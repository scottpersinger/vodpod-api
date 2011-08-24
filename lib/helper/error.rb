module Ramaze
  module Helper
    module Error
      def error(message = 'server error')
        raise API::Error, message
      end

      def error_404
        raise API::NotFoundError, "page not found"
      end

      def error_403(msg = 'forbidden')
        raise API::ForbiddenError, msg
      end
    end
  end
end
