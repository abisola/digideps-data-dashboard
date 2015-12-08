require 'google/api_client'
require 'active_support/all'
require 'date'

# Update these to match your own apps credentials
service_account_email = 'account-1@digideps-analytics.iam.gserviceaccount.com' # Email of service account
key_file = '/app/ga-key.p12' # File containing your private key
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

  #first day of the week
  _t = Time.now

  _week_start = _t.beginning_of_week.strftime("%Y-%m-%d")

  print('start date of the week: ')
  puts(_week_start)

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

  # Execute the query
  registrations_this_week = client.execute(:api_method => analytics.data.ga.get, :parameters => {
    'ids' => "ga:" + profileID,
    'start-date' => _week_start,
    'end-date' => endDate,
    # 'dimensions' => "ga:month",
    'metrics' => "ga:uniquePageviews",
    'filters' => 'ga:pagePath==/client/add',
    # 'sort' => "ga:month" reports-submitted /client/add
  })

  # Execute the query
  submissions_this_week = client.execute(:api_method => analytics.data.ga.get, :parameters => {
    'ids' => "ga:" + profileID,
    'start-date' => _week_start,
    'end-date' => endDate,
    'metrics' => "ga:uniquePageviews",
    'filters' => 'ga:pagePath==reports-submitted',
  })

  count_of_regs = registrationsCount.data.rows.nil? ? 0 : registrationsCount.data.rows[0][0].to_i
  count_of_submits = submissionsCount.data.rows.nil? ? 0 : submissionsCount.data.rows[0][0].to_i
  count_of_regs_this_week = registrations_this_week.data.rows.nil? ? 0 : registrations_this_week.data.rows[0][0].to_i
  count_of_submits_this_week = submissions_this_week.data.rows.nil? ? 0 : submissions_this_week.data.rows[0][0].to_i

  # Update the dashboard
  # Note the trailing to_i - See: https://github.com/Shopify/dashing/issues/33
  send_event('registrations_count',   { current:  count_of_regs})

  send_event('submissions_count',   { current: count_of_submits })

  send_event('submissions_this_week',   { current:  count_of_submits_this_week})

  send_event('registrations_this_week',   { current: count_of_regs_this_week })

end
