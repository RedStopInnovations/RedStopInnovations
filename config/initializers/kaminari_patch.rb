module Kaminari
  module Helpers
    class Tag
      def page_url_for(page)
        @template.url_for params_for(page)
      end
    end
  end
end
