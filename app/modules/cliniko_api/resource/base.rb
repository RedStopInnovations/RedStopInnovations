module ClinikoApi
  module Resource
    class Base
      include Virtus.model
      attr_reader :client

      class << self
        def resources_collection_key
          name.split('::').last.underscore.pluralize
        end

        def resource_base_path
          "/#{resources_collection_key}"
        end

        def parse_resources_collection_data(json_body)
          entries = []

          json_body[resources_collection_key].each do |raw_entry|
            resource = new
            resource.attributes = raw_entry.deep_symbolize_keys
            entries << resource
          end

          ClinikoApi::ResourceCollection.new(entries, json_body.fetch('total_entries'))
        end

        def parse_resource_data(json_body)
          resource = new
          resource.attributes = json_body.deep_symbolize_keys
          resource
        end
      end

      def initialize(client = nil)
        @client = client
      end

      def all(query = {})
        self.class.parse_resources_collection_data(
          client.call(
            :get, "#{self.class.resource_base_path}", standardize_api_query(query.clone))
        )
      end

      def find(id)
        self.class.parse_resource_data(
          client.call(:get, "#{self.class.resource_base_path}/#{id}")
        )
      end

      protected

      def standardize_api_query(query = {})
        query.each do |k, v|
          case v
          when ActiveSupport::TimeWithZone, Time, DateTime
            query[k] = v.utc.iso8601
          when Date
            query[k] = v.iso8601
          when Hash
            sanitize_query v
          when Array
            v.flatten.each { |x| sanitize_query(x) if x.is_a?(Hash) }
          end
        end
        query
      end
    end
  end
end
