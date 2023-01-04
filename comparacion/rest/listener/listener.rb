require "http"

response = HTTP.get("http://localhost:4567/list-matches").parse
match = response["matches"][0]

response = HTTP.get("http://localhost:4567/listen-match/#{match}")
response.body.each { |x| puts x }
