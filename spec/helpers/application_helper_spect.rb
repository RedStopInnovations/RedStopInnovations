require "spec_helper"

describe ApplicationHelper do
  describe "function format_money" do
    it "returns default currency AUD" do
      helper.format_money(100).should eql("$100.00")
    end

    it "returns currency EUR" do
      helper.format_money(100, 'EUR').should eql("€100.00")
    end
  end
end