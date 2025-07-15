require 'net/http'
require 'json'
require 'uri'

class RoutePlanner
  attr_accessor :addresses, :with_login

  def initialize(options={})
    @addresses  = options[:addresses]
    @with_login = options[:with_login]
  end

  def fetch_url
    response = send_address
    if response[:success]
      responseJson = JSON.parse(response[:body])
      dataId = responseJson['UploadToken']
      url = "https://planner.myrouteonline.com?pin=4321&dataid=#{dataId}"

      if @with_login
        login_token = get_login_token(do_login)
        url += "&logintoken=#{login_token}"
      end

    end
    return url
  end

  def send_address
    uri = URI.parse("#{credentials[:server_url]}?m=uploadInputData")
    http = Net::HTTP.new(uri.host, uri.port)

    resp = {}
    response = Net::HTTP::post_form(uri, set_params)
    if( response.is_a?( Net::HTTPSuccess ) )
       resp = {success: true, body: response.body}
     else
       resp = {success: false, body: response.body}
    end
    return resp
  end

  def request_body
    {
      AutoStartMessage: false,
      Parameters: {
        DefaultServiceTimeInMinutes: 480,
        StartAddressIndex: 0,
        EndAddressIndex: 0
      },
      Addresses: addresses
    }
  end

  def credentials
    {
      key: "14cae761-7de8-49df-afff-951fba99b45b",
      server_url: "https://planner.myrouteonline.com/MyRouteOnline/AutomationApi/ServiceInvoker.ashx"
    }
  end

  def set_params
    [
      ['apiToken', credentials[:key]],
      ['userPIN', '4321'],
      ['input', request_body.to_json]
    ]
  end

  def do_login
    uri = URI.parse("#{credentials[:server_url]}?m=getLoginToken")
    params = []
    params << ['apiToken', credentials[:key]]
    params << ['pinCode', '4321']
    params << ['userLogin', 'ben@bardonphysio.com.au']
    params << ['userPassword', 'robert2244']
    params << ['userFullName', 'Ben strachan']
    response = Net::HTTP::post_form(uri, params)
  end

  def get_login_token(resp)
    loginToken = if ( resp.is_a?( Net::HTTPSuccess ) )
        resp = JSON.parse(resp.body)
        resp['LoginToken']
    else
      nil
    end
  end

end
