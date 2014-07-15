require 'rubygems'
require 'rack'
require 'sinatra/base'
require 'omniauth-shopify-oauth2'
require 'json'

require './product'
require './carrier_service'
require './fulfillment_service'

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
    erb :index, locals: {products: Product.new(session).all, carrier_service: session[:carrier_service], fulfillment_service: session[:fulfillment_service]}
  end

  # Carrier Services
  post '/register_carrier' do
    carrier = CarrierService.new(session)
    redirect to('/') if carrier.registered?
    session[:carrier_service] = true if carrier.register
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
    session[:fulfillment_service] = true if fulfillment.register
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
