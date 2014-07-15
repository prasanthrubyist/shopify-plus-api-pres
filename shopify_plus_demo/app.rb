require 'rubygems'
require 'rack'
require 'sinatra/base'
require 'omniauth-shopify-oauth2'
require 'json'
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

class Product < Resource
  attr_reader :client
  def initialize(session)
    super
    @client = make_client('products.json')
  end

  def all
    @all ||= JSON.parse(client.get(headers))['products']
  end
end

class CarrierService < Resource
  def initialize(session)
    if session
      super
      @service_url = "#{external_url}/rates"
      @client = make_client('carrier_services.json')
    end
  end

  def register
    carrier_service = {
      name: 'Shopify Plus Demo Carrier',
      callback_url: @service_url,
      format: 'json',
      service_discovery: true
    }
    client.post({carrier_service: carrier_service}, headers)
  end

  def registered?
    services = JSON.parse(client.get(headers))['carrier_services']
    services.any? { |service| service['callback_url'] == @service_url }
  end

  def rates(request)
    rates = []
    if request['destination']['city'] == 'Toronto'
      rates << {
        service_name: 'Escargo Express -- Bike Courier',
        service_code: 'EE-Bike',
        total_price: 500,
        currency: 'CAD'
      }
    end

    if request['destination']['country'] == 'CA'
      rates << {
        service_name: 'Escargo Express -- National',
        service_code: 'EE-National',
        total_price: 1500,
        currency: 'CAD'
      }
    end

    rates << {
        service_name: 'Escargo Express -- Neglected Class',
        service_code: 'EE-Neglected',
        total_price: 100,
        currency: 'CAD',
    }
    {rates: rates}
  end
end

class FulfillmentService < Resource
  def initialize(session)
    if session
      super
      @service_url = "#{external_url}/fulfillments"
      @client = make_client('fulfillment_services.json')
    end
  end

   def register
    carrier_service = {
      name: 'Moms Friendly Robot Co',
      callback_url: @service_url,
      format: 'json',
      inventory_management: true,
      tracking_support: true,
      requires_shipping_method: true
    }
    client.post({fulfillment_service: carrier_service}, headers)
  end

  def registered?
    services = JSON.parse(client.get(headers))['fulfillment_services']
    services.any? { |service| service['callback_url'] == @service_url }
  end

  def stock_levels(sku=nil)
    stock_levels = {
      "abra" => 50,
      "cadabra" => 100,
      "alakazam" => 20
    }
    sku ? stock_levels[sku] : stock_levels
  end

  def tracking_numbers(order_ids)
    {}
  end
end

class ShopifyPlusDemo < Sinatra::Base
  enable :sessions
  set :session_secret, '2dff6b43237fe58c21d1b28f651c7b58'

  # Configure Ominauth middleware
  use OmniAuth::Builder do
    provider :shopify, '0241b0c738afeff6dcc0ba15bfddaf40', 'a34a74a13bd4e5df65d945abf32a505c',
    scope: 'read_products,write_shipping,write_fulfillments',
    setup: lambda { |env|
      params = Rack::Utils.parse_query(env['QUERY_STRING'])
      env['omniauth.strategy'].options[:client_options][:site] = "https://#{params['shop']}"
    }
  end

  get '/' do
    redirect to('/login') unless session[:access_token]
    erb :index, locals: {products: Product.new(session).all, carrier_service: session[:registered_carrier], fulfillment_service: session[:registered_fulfillment]}
  end

  # Carrier Services
  post '/register_carrier' do
    carrier = CarrierService.new(session)
    redirect to('/') if carrier.registered?
    carrier.register
    redirect to('/')
  end

  post '/rates' do
    content_type :json
    carrier = CarrierService.new({})
    rates = carrier.rates(JSON.parse(request.body.read)['rate'])
    rates.to_json
  end

  # Fulfillment Services

  post '/register_fulfillment' do
    fulfillment = FulfillmentService.new(session)
    redirect to('/') if fulfillment.registered?
    fulfillment.register
    redirect to('/')
  end

  get '/fulfillments/fetch_tracking_numbers.json' do
    content_type :json
    response = {
      message: "Canned response",
      success: true,
      tracking_numbers: {}
    }
    response[:tracking_numbers] = params[:order_ids].reduce({}) do |result, id|
      result[id] = SecureRandom.hex
      result
    end
    response.to_json
  end

  get '/fulfillments/fetch_stock.json' do
    content_type :json
    fulfillment = FulfillmentService.new({})
    fulfillment.stock_levels(params[:sku]).to_json
  end

  # Authentication
  get '/login' do
    erb :login
  end

  get '/logout' do
    session.clear
    redirect to('/')
  end

  get '/auth/:provider/callback' do
    token = request.env["omniauth.auth"]["credentials"]["token"]
    session[:access_token] = token
    session[:shop] = params[:shop]
    redirect to('/')
  end
end
