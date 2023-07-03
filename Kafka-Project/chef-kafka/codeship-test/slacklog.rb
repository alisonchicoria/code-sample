# posts a message into slack channel prod-changes on cookbook upload
require 'net/http'
require 'json'
require 'openssl'
require 'uri'

class SlackLog
  URL = 'https://hooks.slack.com/services/T024G09QW/'\
    'BKEH74WV6/rPBIOSa763Z9GMF3eEbDpb8P'.freeze

  def self.message(channel, message)
    uri = URI.parse(URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.request_uri)
    postdata = {
      'channel' => channel,
      # 'username' => 'chef-notifier', # (now set via webhook)
      'text' => message,
      'icon_emoji' => ':chef:',
    }
    request.body = postdata.to_json
    http.request(request)
    warn("Published to slack: #{message}")
  end
end

metadata_version = cookbook_name = nil
File.open('metadata.rb', 'r') do |file|
  file.each_line do |line|
    result = /^version\s+'(.+)'\s*$/.match(line)
    metadata_version = result[1] if result

    result = /^name\s+'(.+)'\s*$/.match(line)
    cookbook_name = result[1] if result
  end
end

if ARGV[0] == 'cg_version_message'
  if ENV['CI_COMMITTER_NAME'].to_s != ''
    SlackLog.message('#chef-maintainers', "Cookbook #{cookbook_name}-#{metadata_version} pushed by #{ENV['CI_COMMITTER_NAME']} has an out of date code_generator")
  else
    warn('CI_COMMITTER_NAME not set - just printing locally')
    warn("Cookbook #{cookbook_name}-#{metadata_version} has an out of date code_generator")
  end
else
  SlackLog.message('#prod-changes-oregon', "Cookbook #{cookbook_name}-#{metadata_version} changed by #{ENV['CI_COMMITTER_NAME']} uploaded to chef server")
end
