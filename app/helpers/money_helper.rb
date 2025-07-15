module MoneyHelper
  def format_money_amount amount_in_dollar, currency = nil, delimiter = nil
    currency ||= App::DEFAULT_CURRENCY

    money = Money.from_amount amount_in_dollar.to_f, currency
    money.format(delimiter: delimiter)
  end
end
