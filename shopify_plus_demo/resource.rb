require 'rest_client'

class Resource
  attr_reader :client
  def initialize(session)
    @access_token = session[:access_token]
    @root_path = "https://#{session[:shop]}/admin/"
  end

  protected
  def headers
    {'X-Shopify-Access-Token' => @access_token}
  end

  def make_client(path)
    @client = RestClient::Resource.new("#{@root_path}#{path}")
  end

  def external_url
    external_url = ENV['EXTERN_URL']
    external_url ? external_url : raise(StandardError, 'Missing EXTERN_URL environment variable')
  end
end
