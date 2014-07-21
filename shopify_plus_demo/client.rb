require 'rest_client'

class Client
  attr_reader :headers
  def initialize(session)
    @headers = {
      'X-Shopify-Access-Token' => session[:access_token]
    }
    @host = "https://#{session[:shop]}"
  end

  def get(path)
    fullpath = "#{@host}#{path}"
    RestClient.get(fullpath, headers)
  end

  def post(path, data)
    fullpath = "#{@host}#{path}"
    RestClient.post(fullpath, data, headers)
  end

  def put(path, data)
    fullpath = "#{@host}#{path}"
    RestClient.put(fullpath, data, headers)
  end

  def delete(path)
    fullpath = "#{@host}#{path}"
    RestClient.delete(fullpath, headers)
  end
end
