module Trigger
  class Report
    attr_accessor :mentions_count, :patients_count

    def initialize(mentions_count, patients_count)
      @mentions_count = mentions_count
      @patients_count = patients_count
    end
  end
end
