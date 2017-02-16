class Game

  attr_reader :game_number,
              :guess,
              :high_low,
              :guess_count,
              :game_content_type,
              :game_content_length,
              :game_client


  def initialize
    @game_number = rand(101)
    @guess_count = 0
  end

  def make_guess(game_content_type, game_content_length, game_client)
      if game_content_type.include? 'form-data'
        @guess = game_client.read(game_content_length.to_i).split("\r\n")[-2].to_i
      else
        @guess = game_client.read(game_content_length.to_i).split('=')[1].to_i
      end
      guess_checker if game_number != nil
  end

  def guess_checker
    if guess > game_number
      @high_low = "too high."
    elsif guess < game_number
      @high_low = "too low."
    else
      @high_low = "CORRECT!!!"
    end
    @guess_count += 1
  end

  def game_info
    if game_number != nil
      game_response = "You have made #{guess_count} guesses.\n\nYour guess of #{guess} is #{high_low}"
      @game_number = nil if high_low == "CORRECT!!!"
    else
      game_response = "Please start a new game."
    end
    game_response
  end

end
