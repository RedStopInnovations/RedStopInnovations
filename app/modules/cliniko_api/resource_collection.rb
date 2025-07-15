module ClinikoApi
  class ResourceCollection
    attr_reader :entries, :total_entries

    def initialize(entries, total_entries)
      @entries = entries
      @total_entries = total_entries
    end

    def inspect
      "Total entries: #{total_entries}"
    end
  end
end
