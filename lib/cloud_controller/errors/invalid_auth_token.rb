module CloudController
  module Errors
    class InvalidAuthToken < RuntimeError
      def name
        'InvalidAuthToken'
      end

      def response_code
        401
      end

      def message
        'Invalid Auth Token'
      end

      def code
        1000
      end
    end
  end
end
