class Referee
  def observe(event)
    foul = event =~ /barre/i

    foul ? "Falta" : nil
  end
end
