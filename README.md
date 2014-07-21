# Shopify Plus API Demo

This is the content of the presentation that was given the the Shopify Plus workshop in Toronto, Ontario
on the 18th of July, 2014.

The slides can be viewed using Deckset, or by simply opening the included Shopify API PDF document. The PDF
on it's own isn't that useful, so it is suggested to follow along in presentation.md

The lines with carats (^) are the commentary that was used during the presentation.

## Shopify App Demo

The app demo is a simple [Sinatra](http://www.sinatrarb.com/) application that leverages [rest-client](https://rubygems.org/gems/rest-client) for making the API calls.

The application provides examples of how to do the following:

- Setting up [Omniauth](https://github.com/intridea/omniauth) for [Shopify](https://github.com/Shopify/omniauth-shopify-oauth2)
- Performing simple [API Calls to the Products API](http://docs.shopify.com/api/product).
- Acting as a [Carrier Service](http://docs.shopify.com/api/carrierservice) to provide shipping rates during the checkout process
- Acting as a [Fulfillment Service](http://docs.shopify.com/api/fulfillmentservice) to provide fulfillment details and inventory information for various Product SKUs

In order to fully run the application you'll need a [Shopify Partner Account](https://app.shopify.com/services/partners/) and [ngrok](https://ngrok.com) running such that Shopify can make Fulfillment and Carrier Service calls to your app. If ngrok were running at **http://application.ngrok.com** you would start up the demo as follows:

```
cd shopify_plus_demo
EXTERN_URL=http://application.ngrok.com rackup config.ru
```

**You will need to update the callback URL for your application**. Otherwise Shopify will respond with an error.

## Tools and Utilities

- [Postman](https://www.getpostman.com/) allows you to make simple API calls to various web services. It is used was used as the tool during the presentation to allow people to interact with the API and see what their actions would do to a shopify store.
- [Ngrok](https://ngrok.com/) is a tool that makes it easy to expose your development environment to the world. It's cross-platform and simple to use.
- [RequestBin](http://requestb.in/) gives you a bucket to capture external requests. This is useful for seeing what the content of a [Shopify Webhook](http://docs.shopify.com/api/webhook) are. **The Postman webhook examples will require you to create a new bin before they will work correctly**
- You can use the [Shopify Postman Demo](https://shopify-postman-demos.herokuapp.com/login) to get Postman examples that are specific to your production or development shop.
