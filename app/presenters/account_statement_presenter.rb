class AccountStatementPresenter < BasePresenter
  def format_money(amount_in_dollar, target_currency = nil)
    if target_currency
      currency = target_currency
    else
      currency = display_currency
    end

    money = Money.from_amount amount_in_dollar.to_f, currency
    money.format
  end

  def display_currency
    @display_currency ||= begin
      business.currency || App::DEFAULT_CURRENCY
    end
  end
end