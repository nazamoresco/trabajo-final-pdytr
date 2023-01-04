
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

        yield next_line
      end
    end

    real_time_match_listener.each do |aca|
      aca
    end

    real_time_match_listener.each { |result| puts result; yield result }
  end
end
