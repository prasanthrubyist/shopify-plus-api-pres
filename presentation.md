# Shopify Plus

### The Shopify API -- Chris Saunders

---

# API?

## Not every customer requirement should exist as a feature within Shopify

---

# How we justify a feature

- Can every customer use it?
  - Add it to Shopify
- Do some customers need it?
  - Make it an app
- Does one customer need it?
  - Custom Application

---

# What kinds of needs do Plus customers have?

---

## Unique Integrations

## More features than what Shopify offers

## Deeper Analysis

## Complex Processing

---

# Accessing the API

## Private Apps
## OAuth 2

---

# Private Apps

### These work for a single shop
### Authentication is simple Basic Auth
### Are created through the admin
### Full API Permissions

---

# OAuth Apps

### Granular API Access
### Application will be used by more than one shop

---

# OAuth

- There are plenty of libraries that exist which makes OAuth very straight forward
- In ruby there is the omniauth-shopify-oauth2 gem

---

# OAuth in Ruby

```ruby
require 'rubygems'
require 'rack'
require 'sinatra'
require 'omniauth-shopify-oauth2'

# Configure Ominauth middleware
use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :shopify, 'api key', 'shared secret',
           scope: 'read_products',
           setup: lambda { |env|
            params = Rack::Utils.parse_query(env['QUERY_STRING'])
            env['omniauth.strategy'].options[:client_options][:site] = "https://#{params['shop']}"
          }
end

# Login Screen
get '/' do
  '''
  <form method="get" action="/auth/shopify">
    <input type="text" name="shop" />
    <input type="submit" value="Login with Shopify" />
  </form>
  '''
end

# Application Success
get '/auth/:provider/callback' do
  '''
  <p>Your access token is: #{request.env["omniauth.auth"]["credentials"]["token"]}</p>
  '''
end

# Failure :(
get '/auth/failure' do
  "(V)(;,,,;)(V) Something went wrong!"
end

```

---

# Working with the API

```ruby
# Fetch a list of orders
require 'net/http'
uri = URI('https://justmops.myshopify.com/admin/orders.json')
Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |client|
  request = Net::HTTP::Get.new(uri)
  request['Content-Type'] = 'application/json'
  request['Accept'] = 'application/json'
  request['X-Shopify-Access-Token'] = 'access token'

  response = client.request(request)
  # Let's just grab the first 30 characters
  puts response.body[0..30]
  # {"orders":[{"buyer_accepts_mark
end
```

---

# REST and Shopify

All<sup>*</sup> of Shopifys resources follow a similar pattern:

- List a page of Resources:
  `GET https://domain/admin/resource_name.json`
- List a single Resource:
  `GET https://domain/admin/resource_name/resource_id.json`

---

# REST and Shopify

- Create a Resource:
  `POST https://domain/admin/resource_name.json`
- Update a Resource:
  `PUT https://domain/admin/resource_name/resource_id.json`
- Destroy a Resource:
  `DELETE https://domain/admin/resource_name/resource_id.json`

---

# Aspects of the API

- API Resources (orders, products, etc)
- Application Proxies & Script Tags
- Customer Login Providers (Multipass login)
- Webhooks
- App Links


---

# Shopify API Resources

The data in a response can be sent back to Shopify to update a resource:

```ruby
require 'net/http'
require 'json'
uri = URI('https://justmops.myshopify.com/admin/orders/1234.json')
content = JSON.parse(authenticated_get_request(uri))
# All Shopify resources are wrapped in a root object (pluralized for collections)
order = content['order']
order['note'] = 'Just jotting down a couple of notes on the order'

Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |client|
  request = Net::HTTP::Put.new(uri)
  request['X-Shopify-Access-Token'] = 'access token'
  request['Content-Type'] = 'application/json'
  request['Accept'] = 'application/json'
  request.body = {'order' => order}.to_json

  response = client.request(request)
  # List, Show and Update all return 200 OK
  puts response.code # 200
end
```

---

# Serving your Apps

Use the Embedded App SDK to give your customers a nicer experience

- Provides hooks to use Shopify styled modals, popups, etc.
- Keep user within their Admin instead of going to another website

---

# Safely Interfacing with a Merchants Storefront

## Modifying templates is messy
### Breaks the rule of "never leave a trace"
### Changes are lost if merchant installs new theme

---

# Application Proxies

![](app-proxies.png)

- Allow you to render data in the storefront
- Can return liquid and Shopify will render it!

---

# Application Proxy Example

```ruby
require 'sinatra'

before do
  halt 401, 'Unauthorized' unless verify_authenticity
end

get '/' do
  headers 'Content-Type' => 'application/liquid'
  """
  <p>Products with Even Ids</p>
  {% for product in collections['animate-objects'].products %}
    <ul>
      {% if product.id | modulo:2 | == 0 %}
        <li>{{ product.title }}</li>
      {% endif %}
    </ul>
  {% endfor %}
  """
end
```

---

# Script Tags

- Easily embed custom javascript in a merchants storefront
- Always rendered regardless of when installed
- Need to be hosted somewhere (your server, S3, etc.)

---

# Registering a Script Tag

```ruby
require 'net/http'
require 'json'
# Let's ignore the boilerplate
setup_client('script_tags.json') do |client, uri|
  script_tag = {
    script_tag: {
      src: 'http://yourservice.com/some.js'
    }
  }
  request = Net::HTTP::Post.new(uri)
  request.body = script_tag.to_json

  response = client.request(request)
  puts response.code # 201
end
```

---

# Multipass

- Provide a way for a user on another property to login as a customer on the shop
- Token validity is short-lived. Generation needs to be done as required
- Shop needs to have multipass enabled on their Checkout Settings

---

# Registering a Multipass Customer

```ruby
# Should this be a more involved demo?
# http://docs.shopify.com/api/tutorials/multipass-login
require 'base64'

secret = 'secret from admin'
customer_data = {
  email: 'snake-plisken@example.com',
  created_at: '1997-06-01',
  first_name: 'Bob',
  last_name: 'Plisken'
}
```

---

# App Links

![](application-link.png)

- Provide contextual actions on shopify resources
- Shortcuts to areas of your application
- Added through the Partner Dashboard

---

# Webhooks

- Let us tell you when things have changed
- Don't bite into your API call limits
- Let you subscribe to the kinds of data you are interested in
- Data is signed

---

# Webhook Gotchas

- You need the right permissions to register for a webhook
  - Can't register for order creation webhooks if you can only read products
- Don't include historical data
  - Webhooks contain a snapshot of the data when it was delivered, not when it was queued

---

# Webhook Gotchas

- The data in the webhook is slightly different from our API responses
  - No root node (i.e. {data} instead of {order: {data}})

---

# Registering a Webhook

```ruby
require 'net/http'
require 'json'
setup_client('webhooks.json') do |client, uri|
  webhook = {
    type: 'json',
    topic: 'product/update'
    address: 'http://yourserver.com/shopify/webhooks'
  }
  request = Net::HTTP::Post.new(uri)
  request.body = {webhook: webhook}.to_json

  client.request(request)
end
```

---

# Validating a Webhook

```
require 'sinatra'
require 'openssl'
require 'base64'

post '/shopify/webhooks' do
  process_in_background(params) if valid_webhook?
end

SECRET = 'my app secret'

def valid_webhook?
  request.body.rewind
  data = request.body.read
  digest = OpenSSL::Digest::Digest.new('sha256')
  calculated_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest, SECRET, data)
  request['X-Shopify-Hmac-SHA256'] == calculated_hmac
end
```

---

# Tools

- Exposing development environments to the world
- API Client Libraries
- Ways to Easily Play with the API

---

# Exposing your environment to the world

`ngrok 3000`

- You can use ngrok to expose your development server to the world
- Use the given domain when registering webhooks, carrier services, etc.

---

# Official API Client Libraries

## github.com/shopify/shopify_api
## github.com/shopify/shopify\_python\_api

---

# API Client Libraries

## As demonstrated, using the API doesn't require a client. Your HTTP library can do the work if necessary

---

# Playing with the API

![original](postman.png)

---

# Getting Help

---

# ecommerce.shopify.com/c/shopify-apis-and-technology
