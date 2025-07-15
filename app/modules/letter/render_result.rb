module Letter
  class RenderResult
    attr_reader :content, :missing_variables

    def initialize(content, missing_variables = [])
      @content = content
      @missing_variables = missing_variables
    end

    def as_json(_options = {})
      {
        content: content,
        missing_variables: missing_variables
      }
    end
  end
end
