this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir.gsub(/servidor/i, ""), 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'grpc'
require 'football_services_pb'

class MatchListener
  def initialize(match)
    @match = match
  end

  def each
    return enum_for(:each) unless block_given?

    file = File.open("partidos/#{@match}", "r")
    file.each_line do |line|
      yield Football::ListenMatchResponse.new(
        event: line
      )
    end
  end
end


class Server < Football::Football::Service
  def list_matches(email_req, _unused_call)
    Football::ListMatchesResponse.new(
      matches: Dir["./partidos/*"].map { |match| match.gsub(/\.\/partidos\//i, "") }.sort
    )
  end

  def comment_match(comment_reqs)
    file = nil
    comment_reqs.each_remote_read do |comment_req|
      file ||= File.open("partidos/#{comment_req.match}", "a") 
      file << "#{comment_req.comment}\n" 
    end
    
    file.close
    Football::CommentMatchResponse.new
  end

  def listen_match(listen_req, _unused_call)
    MatchListener.new(listen_req.match).each
  end
end

server = GRPC::RpcServer.new
server.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
server.handle(Server)
server.run_till_terminated_or_interrupted([1, 'int', 'SIGTERM'])
