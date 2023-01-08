this_dir = __dir__
lib_dir = File.join(this_dir.gsub(/\/server$/i, ""), "lib")
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "grpc"
require "football_services_pb"

class MatchListener
  def initialize(match)
    @match = match
  end

  def each
    return enum_for(:each) unless block_given?

    real_time_match_listener = Enumerator.new do
      lines = File.open("matches/#{@match}", "r").each_line
      already_read_bytes = 0

      loop do
        next_line = nil
        waits = 10

        while next_line.nil?
          begin
            next_line = lines.next
            already_read_bytes += next_line.length
          rescue StopIteration
            sleep(1) # Wait a second for new lines
            file = File.open("matches/#{@match}", "r")
            file.seek(already_read_bytes)
            lines = file.each_line
            waits -= 1

            raise if waits == 0
          end
        end

        yield Football::ListenMatchResponse.new(
          event: next_line
        )
      end
    end

    real_time_match_listener.each { |result| yield result }
  end
end

class Referee
  def observe(event)
    foul = event =~ /barre/i

    foul ? "Falta" : nil
  end
end

class Server < Football::Football::Service
  def list_matches(email_req, _unused_call)
    Football::ListMatchesResponse.new(
      matches: Dir["./matches/*"].map { |match| match.gsub(/\.\/matches\//i, "") }.sort
    )
  end

  def comment_match(comment_reqs)
    referee = Referee.new

    comment_reqs.each_remote_read do |comment_req|
      file = File.open("matches/#{comment_req.match}", "a")
      file << "#{comment_req.comment}\n"

      santion = referee.observe(comment_req.comment)
      file << "#{santion}\n" unless santion.nil?

      file.close
    end

    Football::CommentMatchResponse.new
  end

  def listen_match(listen_req, _unused_call)
    MatchListener.new(listen_req.match).each
  end
end

server = GRPC::RpcServer.new
server.add_http2_port("0.0.0.0:50051", :this_port_is_insecure)
server.handle(Server)
server.run_till_terminated_or_interrupted([1, "int", "SIGTERM"])
