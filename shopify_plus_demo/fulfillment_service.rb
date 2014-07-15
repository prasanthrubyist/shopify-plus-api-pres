require './resource'

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
