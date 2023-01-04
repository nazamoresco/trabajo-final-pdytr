require "json"
require "http"
require_relative "commentator"

response = HTTP.get("http://localhost:4567/list-matches").parse
matches = response["matches"]

match = matches[0]
commentator = Commentator.new(
  local: match.split("-")[0],
  visitor: match.split("-")[1]
)

begin
  http = HTTP.persistent "http://localhost:4567"

  100.times { http.put("/comment-match/#{match}", json: { comment: commentator.comment }).flush }
ensure
  http.close if http
end
