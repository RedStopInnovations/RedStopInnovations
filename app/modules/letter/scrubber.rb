module Letter
  # Custom sanitization rules for letter conent
  class Scrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = %w(strong em b i u p pre code hr br div span h1 h2 h3 h4 h5 h6 ul ol li dl dt dd a img blockquote table thead tbody tr td th)
      self.attributes = %w(href style src width height alt target border cellpadding cellspacing)
    end
  end
end
