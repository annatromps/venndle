class AnthropicJudgeService
  def self.call(guess, correct_label, circle_words)
    raise ArgumentError, "ANTHROPIC_API_KEY not configured" if ENV["ANTHROPIC_API_KEY"].blank? || ENV["ANTHROPIC_API_KEY"] == "your_api_key_here"

    client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])
    prompt = "The category label is: \"#{correct_label}\". The player guessed: \"#{guess}\". The words in this circle are: #{circle_words.join(", ")}.\n\nA correct guess should be accepted if it is a synonym, related word, adjective/noun variation, or reasonable paraphrase of the correct label AND it genuinely applies to all the words in the circle. Be generous — accept:\n- Adjective/noun/adverb forms of the same root (round/rounded/spherical/sphere, sharp/sharpness, thin/thinness/skinny/slim/narrow)\n- Synonyms and near-synonyms\n- More specific or more general versions (e.g. 'metal' accepted for 'silver', 'colour' accepted for 'yellow things')\n- Informal or colloquial phrasings\n\nOnly reject if the guess is clearly wrong or describes something genuinely different. When in doubt, accept.\n\nRespond with only YES or NO."
    response = client.messages(
      parameters: {
        model: "claude-sonnet-4-20250514",
        max_tokens: 10,
        messages: [{ role: "user", content: prompt }]
      }
    )
    response.dig("content", 0, "text").to_s.strip.upcase.start_with?("YES")
  rescue => e
    Rails.logger.error "AnthropicJudgeService error: #{e.class}: #{e.message}"
    # Fall back to exact/case-insensitive match so the game still works
    guess.strip.downcase == correct_label.to_s.strip.downcase
  end
end
