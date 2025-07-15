module Api
  module V1
    module PaginationHelpers
      DEFAULT_PAGE_SIZE = 100

      def jsonapi_pagination(collection)
        pagination = {}

        if collection.respond_to?(:total_pages)
          pagination[:first] = url_to_first_page(collection)
          pagination[:last] = url_to_last_page(collection)

          pagination[:prev] =
            if collection.first_page?
              nil
            else
              pagination[:prev] = url_to_prev_page(collection)
            end

          pagination[:next] =
            if collection.last_page?
              nil
            else
              pagination[:next] = url_to_next_page(collection)
            end
        end
        pagination
      end

      def pagination_meta(collection)
        meta = {
          per_page: pagination_params[:size],
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_entries: collection.total_count,
        }

        if jsonapi_filter_params.present?
          meta[jsonapi_filter_key] = jsonapi_filter_params
        end

        meta
      end

      def pagination_params
        @pagination_params ||= begin
          prms = {
            number: params.dig(:page, :number),
            size: params.dig(:page, :size)
          }

          if prms[:number].present?
            prms[:number] = prms[:number].to_i
          else
            prms[:number] = 1
          end

          if prms[:size].present?
            prms[:size] = prms[:size].to_i
            unless prms[:size] >=1
              prms[:size] = 1
            end

            if prms[:size] > DEFAULT_PAGE_SIZE
              prms[:size] = DEFAULT_PAGE_SIZE
              # NOTE: raise bad request instead?
            end
          else
            prms[:size] = DEFAULT_PAGE_SIZE
          end

          prms
        end
      end

      def default_pagination_params
        {
          number: 1,
          size: DEFAULT_PAGE_SIZE
        }
      end

      def url_to_next_page(scope, options = {})
        return unless scope.next_page

        url_for options.merge(
          only_path: false,
          page: {
            number: scope.prev_page,
            size: scope.limit_value
          }
        ).merge(jsonapi_filter_key => jsonapi_filter_params)
      end

      def url_to_prev_page(scope, options = {})
        return unless scope.prev_page

        url_for options.merge(
          only_path: false,
          page: {
            number: scope.prev_page,
            size: scope.limit_value
          }
        ).merge(jsonapi_filter_key => jsonapi_filter_params)
      end

      def url_to_first_page(scope, options = {})
        return unless scope.total_pages.positive?

        url_for options.merge(
          only_path: false,
          page: {
            number: 1,
            size: scope.limit_value
          }
        ).merge(jsonapi_filter_key => jsonapi_filter_params)
      end

      def url_to_last_page(scope, options = {})
        return unless scope.total_pages.positive?

        url_for options.merge(
          only_path: false,
          page: {
            number: scope.total_pages,
            size: scope.limit_value
          }
        ).merge(jsonapi_filter_key => jsonapi_filter_params)
      end
    end
  end
end
