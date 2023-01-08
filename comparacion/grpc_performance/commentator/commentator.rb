this_dir = __dir__
lib_dir = File.join(this_dir.gsub(/commentator/i, ""), "lib")
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "grpc"
require "football_services_pb"
require "benchmark"

class Commentator
  ACTIONS = ["barre", "regatea", "define", "pasa"]
  DIRECTIONS = ["izquierda", "derecha"]
  ACTED = ["arquero", "arco", "defensor", "delantero"]

  def initialize(local:, visitor:)
    @actors = [local, visitor]
  end

  def comment
    "El jugador de #{@actors.sample} #{ACTIONS.sample} a la #{DIRECTIONS.sample} al #{ACTED.sample} de #{@actors.sample}."
  end
end

class CommentsStreamer
  MAX_BYTES = 4_194_308

  def initialize(match)
    @match = match
    @commentator = Commentator.new(
      local: match.split("-")[0],
      visitor: match.split("-")[1]
    )
  end

  def each
    return enum_for(:each) unless block_given?

    100.times do
      yield Football::CommentMatchRequest.new(
        match: @match,
        comment: @commentator.comment
      )
    end
  end
end

stub = Football::Football::Stub.new("localhost:50051", :this_channel_is_insecure)

n = 100
real_times = n.times.map do
  Benchmark.measure { stub.list_matches Football::ListMatchesRequest.new }.real * 1000
end

total_time = real_times.sum
average = total_time / n
standard_deviation = Math.sqrt(real_times.sum { |real_time| (real_time - average) ** 2} / (n - 1))

puts "Total time: #{total_time.round(3)} ms"
puts "Average: #{average.round(3)} ms"
puts "Standard deviation: #{standard_deviation.round(3)} ms"

response = stub.list_matches Football::ListMatchesRequest.new
my_match = response.matches.first

n = 100
real_times = n.times.map do
  Benchmark.measure { stub.comment_match(CommentsStreamer.new(my_match).each) }.real * 1000
end

total_time = real_times.sum
average = total_time / n
standard_deviation = Math.sqrt(real_times.sum { |real_time| (real_time - average) ** 2} / (n - 1))

puts "Total time: #{total_time.round(3)} ms"
puts "Average: #{average.round(3)} ms"
puts "Standard deviation: #{standard_deviation.round(3)} ms"


