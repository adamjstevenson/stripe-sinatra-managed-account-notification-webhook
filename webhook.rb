require 'sinatra'
require 'stripe'
require 'mailgun'

set :secret_key, ENV['STRIPE_KEY']
Stripe.api_key = settings.secret_key

set :mailgun_key, ENV['MAILGUN_KEY']
mg_client = Mailgun::Client.new settings.mailgun_key

# Responds to webhooks sent by Stripe
post '/webhook' do
  status 200
  # Retrieve the request's body and parse it as JSON
  event_json = JSON.parse(request.body.read)

  # Retrieve the event from Stripe
  event = Stripe::Event.retrieve({ id: event_json['id'] }, { stripe_account: event_json['user_id'] })
  # Only respond to `account.updated` events
  if event.type.eql?('account.updated')
    # Determine if identity verification is needed
    unless event.data.object.verification.fields_needed.nil?
      # Send a notification to the connected account
      message_params = {
        from: 'you@yourdomain.com',
        to: event.data.object.email, # The account holder email
        subject: 'Update your account information',
        text: 'Hi there! We need some additional information about your account to continue sending you transfers. You can get update this by following thelink here: https://yourdomain.com/account/submit_info'
      }
      mg_client.send_message('yourdomain.com',message_params)
    end

  else
    # Nothing to see here, return a 200
    status 200
  end
end
