class Game

  attr_reader :game_number,
              :guess,
              :high_low,
              :guess_count

  def initialize
    @game_number = rand(101)
    @guess_count = 0
  end

  def guess_checker(guess)
    if guess > game_number
      @high_low = "too high."
    elsif guess < game_number
      @high_low = "too low."
    else
      @high_low = "CORRECT!!!"
    end
    @guess_count += 1
  end

  def game_info(guess)
    if game_number != nil
      game_response = "You have made #{guess_count} guesses.\n\nYour guess of #{guess} is #{high_low}"
      @game_number = nil if high_low == "CORRECT!!!"
    else
      game_response = "Please start a new game."
    end
    game_response
  end
end
