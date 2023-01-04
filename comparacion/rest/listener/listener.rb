require "net/http"
require "json"

uri = URI("http://localhost:4567/list-matches")
response = Net::HTTP.get(uri)
matches = JSON.parse(response)["matches"]

puts matches