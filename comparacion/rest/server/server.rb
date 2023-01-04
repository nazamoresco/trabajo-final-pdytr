require 'sinatra'
require 'json'
require_relative "referee"
require_relative "match_listener"

get '/list-matches', provides: "application/json" do
  {
    matches: Dir["./matches/*"].map { |match| match.gsub(/\.\/matches\//i, "") }.sort
  }.to_json
end

put '/comment-match/:match_id', provides: "application/json" do
  match = params["match_id"]
  comment = JSON.parse(request.body.read)["comment"]

  referee = Referee.new
  File.open("matches/#{match}", "a") do |file|
    file << "#{comment}\n"

    santion = referee.observe(comment)
    file << "#{santion}\n" unless santion.nil?
  end

  {}.to_json
end

get '/listen-match/:match_id', provides: 'text/event-stream' do
  MatchListener.new(params["match_id"])
end