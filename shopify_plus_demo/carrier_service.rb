require './resource'

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
