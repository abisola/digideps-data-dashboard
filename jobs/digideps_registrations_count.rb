require 'google/api_client'
require 'date'

# Update these to match your own apps credentials
service_account_email = 'account-1@digideps-analytics.iam.gserviceaccount.com' # Email of service account
key_file = '/Users/abisola/dev/Digideps-Analytics-9ababd74caf6.p12' # File containing your private key
key_secret = 'notasecret' # Password to unlock private key
profileID = '105292338' # Analytics profile ID.

# Get the Google API client
client = Google::APIClient.new(:application_name => 'digideps-analytics',
  :application_version => '0.01')

# Load your credentials for the service account
key = Google::APIClient::KeyUtils.load_from_pkcs12(key_file, key_secret)
client.authorization = Signet::OAuth2::Client.new(
  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
  :audience => 'https://accounts.google.com/o/oauth2/token',
  :scope => 'https://www.googleapis.com/auth/analytics.readonly',
  :issuer => service_account_email,
  :signing_key => key)

# Start the scheduler
SCHEDULER.every '5m', :first_in => 0 do

  # Request a token for our service account
  client.authorization.fetch_access_token!

  # Get the analytics API
  analytics = client.discovered_api('analytics','v3')

  # Start and end dates
  startDate = DateTime.now.strftime("%Y-11-17") # first day [17th November, 2015]
  endDate = DateTime.now.strftime("%Y-%m-%d")  # now

  # Execute the query
  registrationsCount = client.execute(:api_method => analytics.data.ga.get, :parameters => {
    'ids' => "ga:" + profileID,
    'start-date' => startDate,
    'end-date' => endDate,
    # 'dimensions' => "ga:month",
    'metrics' => "ga:uniquePageviews",
    'filters' => 'ga:pagePath==/client/add',
    # 'sort' => "ga:month" reports-submitted /client/add
  })

  # Execute the query
  submissionsCount = client.execute(:api_method => analytics.data.ga.get, :parameters => {
    'ids' => "ga:" + profileID,
    'start-date' => startDate,
    'end-date' => endDate,
    'metrics' => "ga:uniquePageviews",
    'filters' => 'ga:pagePath==reports-submitted',
  })

  # Update the dashboard
  # Note the trailing to_i - See: https://github.com/Shopify/dashing/issues/33
  send_event('registrations_count',   { current: registrationsCount.data.rows[0][0].to_i })

  #can we have multiple send_event[s] in the same rb file? only one way to find out...
  send_event('submissions_count',   { current: submissionsCount.data.rows[0][0].to_i })

end
