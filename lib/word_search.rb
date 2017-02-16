class WordSearch

  def initialize(word_request_uri)
    @word_request_uri = word_request_uri
    assign_get_param
  end

  def assign_get_param(line = @word_request_uri)
    query        = URI.unescape(URI(line).query)
    @get_param = query.split('=')[1]
  end

  def dict_search_result(param = @get_param)
    if dict_list.include?(param) == true
      "#{param} is a known word"
    else
      "#{param} is not a known word"
    end
  end

  def dict_list
    File.read('/usr/share/dict/words').split("\n")
  end
end
