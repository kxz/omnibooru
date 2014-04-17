module Iqdb
  module Responses
    class Collection
      def initialize(response_string)
        @responses = response_string.split(/\n/).map do |string|
          ::Iqdb::Responses.const_get("Response_#{string[0..2]}").new(string[4..-1])
        end
      end

      def matches
        @matches ||= responses.select {|x| x.is_a?(Iqdb::Responses::Response_200) && x.score >= 0.9}
      end

      def empty?
        matches.empty?
      end

      def errored?
        errors.any?
      end

      def errors
        @errors ||= responses.select {|x| x.is_a?(Iqdb::Responses::Error)}.map {|x| x.to_s}
      end
    end
  end
end
