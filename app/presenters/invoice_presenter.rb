class InvoicePresenter < BasePresenter
  def business_address
    "#{business.address1} <br>" <<
    (business.address2.presence || '') <<
    "#{business.city}, #{business.state} #{business.postcode}" \
  end

  def business_logo_url
    if Rails.env.production?
      business.avatar.url
    else
      ApplicationController.helpers.asset_url(business.avatar.url)
    end
  end

  def issue_date_formatted
    issue_date.try(:strftime, '%d %b %Y')
  end

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
