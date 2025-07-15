module Utils
  module Image
    def self.parse_from_data_url(data_url)
      if data_url.match(%r{^data:(.*?);(.*?),(.*)$})
        return {
          type: $1, # "image/png"
          encoder: $2, # "base64"
          data: $3, # data string
          extension: $1.split('/')[1] # "png"
        }
      end
    end
  end
end
