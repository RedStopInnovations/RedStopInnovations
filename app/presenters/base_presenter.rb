class BasePresenter < SimpleDelegator

  def initialize(model)
    super(model)
  end

  private

  attr_reader :model
end
