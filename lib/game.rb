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
    if guess_count == 0
      game_response = "Good Luck!"
    else
      if game_number != nil
        game_response = "You have made #{guess_count} guesses.\n\nYour guess of #{guess} is #{high_low}"
      else
        game_response = "Please start a new game."
      end
    end
    game_response
  end
end
