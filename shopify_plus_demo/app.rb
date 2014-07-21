require 'rubygems'
require 'rack'
require 'sinatra/base'
require 'omniauth-shopify-oauth2'
require 'json'

require './client'

class ShopifyPlusDemo < Sinatra::Base
  enable :sessions
  set :session_secret, 'MAKE THIS SOMETHING SECRET'

  # Configure Ominauth middleware
  use OmniAuth::Builder do
    provider :shopify, 'API KEY FROM PARTNERS DASHBOARD', 'API SECRET FROM PARTNERS DASHBOARD',
    scope: 'PERMISSIONS YOU WANT TO USE SUCH AS: read_products',
    setup: lambda { |env|
      params = Rack::Utils.parse_query(env['QUERY_STRING'])
      env['omniauth.strategy'].options[:client_options][:site] = "https://#{params['shop']}"
    }
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

  def client
    Client.new(session)
  end

  def external_url
    external_url = ENV['EXTERN_URL']
    external_url ? external_url : raise(StandardError, 'Missing EXTERN_URL environment variable')
  end

  # Making a Simple API Call
  get '/' do
    redirect to('/login') unless session[:access_token]

    erb :index, locals: {products: get_all_products, carrier_service: session[:carrier_service], fulfillment_service: session[:fulfillment_service]}
  end

  def get_all_products
    response = client.get("/admin/products.json")
    JSON.parse(response.body)['products']
  end

  # Carrier Services
  post '/register_carrier' do
    response = register_carrier_service
    session[:carrier_service] = true if response.code == 201
    redirect to('/')
  end

  def register_carrier_service
    carrier_service = {
      name: 'Shopify Plus Demo Carrier',
      callback_url: "#{external_url}/rates",
      format: 'json',
      service_discovery: true
    }
    client.post('/admin/carrier_services.json', {carrier_service: carrier_service})
  end

  post '/rates' do
    content_type :json
    carrier_rates.to_json
  end

  def carrier_rates
    {
      rates: [
        {
          service_name: 'Escargo Express -- Bike Courier',
          service_code: 'EE-Bike',
          total_price: 500,
          currency: 'CAD'
        },
        {
          service_name: 'Escargo Express -- National',
          service_code: 'EE-National',
          total_price: 1500,
          currency: 'CAD'
        },
        {
          service_name: 'Escargo Express -- Neglected Class',
          service_code: 'EE-Neglected',
          total_price: 100,
          currency: 'CAD',
        }
      ]
    }
  end

  # Fulfillment Services

  post '/register_fulfillment' do
    response = register_fulfillment_service
    session[:fulfillment_service] = true if response.code == 201
    redirect to('/')
  end

  def register_fulfillment_service
    fulfillment_service = {
      name: 'Moms Evil Robot Co',
      callback_url: "#{external_url}/fulfillments",
      format: 'json',
      inventory_management: true,
      tracking_support: true,
      requires_shipping_method: true
    }
    client.post('/admin/fulfillment_services', {fulfillment_service: fulfillment_service})
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
    stock_levels(params[:sku]).to_json
  end

  def stock_levels(sku=nil)
    levels = {
      "abra" => 50,
      "cadabra" => 100,
      "alakazam" => 20
    }
    sku ? {sku => levels[sku]} : levels
  end
end
