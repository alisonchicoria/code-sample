file_location = File.dirname(__FILE__)
log_level :debug
log_location STDOUT
node_name 'codeship-chef'
validation_client_name 'codeship-chef'
client_key "#{file_location}/codeship.pem"
chef_server_url 'https://foodtruck..com/organizations/odesk'
