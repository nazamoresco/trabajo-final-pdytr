this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir.gsub(/listener/i, ""), 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)


require 'grpc'
require 'football_services_pb'

stub = Football::Football::Stub.new('localhost:50051', :this_channel_is_insecure)

response = stub.list_matches Football::ListMatchesRequest.new
my_match = response.matches.first

call = stub.listen_match(Football::ListenMatchRequest.new(match: my_match))

call.each do |event_res|
  puts event_res.event
end