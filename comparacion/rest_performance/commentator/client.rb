require "json"
require "http"
require_relative "commentator"
require "benchmark"


n = 100
real_times = n.times.map do
  Benchmark.measure { HTTP.get("http://localhost:4567/list-matches").parse }.real * 1000
end

total_time = real_times.sum
average = total_time / n
standard_deviation = Math.sqrt(real_times.sum { |real_time| (real_time - average) ** 2} / (n - 1))

puts "Total time: #{total_time.round(3)} ms"
puts "Average: #{average.round(3)} ms"
puts "Standard deviation: #{standard_deviation.round(3)} ms"

response = HTTP.get("http://localhost:4567/list-matches").parse
matches = response["matches"]

match = matches[0]
commentator = Commentator.new(
  local: match.split("-")[0],
  visitor: match.split("-")[1]
)


begin
  http = HTTP.persistent "http://localhost:4567"

  real_times = n.times.map do
    Benchmark.measure { 100.times { http.put("/comment-match/#{match}", json: {comment: commentator.comment}).flush } }.real * 1000
  end
ensure
  http&.close
end


total_time = real_times.sum
average = total_time / n
standard_deviation = Math.sqrt(real_times.sum { |real_time| (real_time - average) ** 2} / (n - 1))

puts "Total time: #{total_time.round(3)} ms"
puts "Average: #{average.round(3)} ms"
puts "Standard deviation: #{standard_deviation.round(3)} ms"