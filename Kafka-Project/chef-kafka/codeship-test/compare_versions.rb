#!/usr/bin/env ruby

def goget_metadata_info(filename = 'metadata.rb')
  # Pull the version out of the metadata.rb
  puts 'Retrieving metadata version...'
  metadata_version = cookbook_name = nil
  File.open(filename, 'r') do |file|
    file.each_line do |line|
      result = /^version\s+'(.+)'\s*$/.match(line)
      metadata_version = result[1] if result

      result = /^name\s+'(.+)'\s*$/.match(line)
      cookbook_name = result[1] if result
    end
  end
  raise 'Unable to determine the name of the cookbook.' unless cookbook_name
  raise 'Unable to determine the version from the metadata.' unless metadata_version
  [metadata_version, cookbook_name]
end

def goget_server_version(cookbook_name)
  puts 'Retrieving server version...'
  knife_version = nil
  output = `bundle exec knife cookbook show #{cookbook_name}`
  result = /^#{cookbook_name}\s+(.+)\s/.match(output)
  knife_version = result[1].split("\s")[0] if result

  knife_version
end

def goget_code_generator_version
  cgv = File.open('.code_generator_version').read.chomp
  cgv
end

if ARGV[0].to_s =~ /code_generator/

  cg_metadata_version = goget_server_version('code_generator')
  local_version = goget_code_generator_version
  # Just compare minor versions, ignore patchlevel
  if Gem::Version.new(cg_metadata_version.gsub(/\.[0-9]*$/, '')) > Gem::Version.new(local_version.gsub(/\.[0-9]*$/, ''))
    puts "code_generator version #{cg_metadata_version} is newer than the version #{local_version} used with this cookbook. code_generator refresh needed (see https://github.com//code_generator#updating-an-existing-cookbook)"
    exit 1
  else
    puts 'Code generator code up to date'
    exit 0
  end

else

  puts 'Comparing metadata version with latest stored on server...'
  metadata_version, cookbook_name = goget_metadata_info('metadata.rb')
  knife_version = goget_server_version(cookbook_name)

  if metadata_version && !knife_version
    puts "Metadata indicates version #{metadata_version} but the cookbook is not present on the server."
    exit 0
  end

  if Gem::Version.new(metadata_version) <= Gem::Version.new(knife_version)
    puts "Version in metadata (#{metadata_version}) is the same or lower than that stored on the server (#{knife_version})."
    exit 1
  else
    puts 'Looks ok.'
    exit 0
  end

end
