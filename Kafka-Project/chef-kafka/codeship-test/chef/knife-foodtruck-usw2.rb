file_location = File.dirname(__FILE__)
log_level :debug
log_location STDOUT
node_name 'codeship'
client_key "#{file_location}/codeship-foodtruck-usw2.pem"

ssl_verify_mode    :verify_none
verify_api_cert    false
chef_server_url 'https://foodtruck-usw2.internal.com/organizations/'
