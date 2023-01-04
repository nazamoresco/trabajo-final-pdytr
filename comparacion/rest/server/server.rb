require 'sinatra'

get '/list-matches' do
  {
    matches: Dir["./matches/*"].map { |match| match.gsub(/\.\/matches\//i, "") }.sort
  }.to_json
end