require './resource'
require 'json'

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
