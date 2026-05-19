class AnthropicJudgeService
  def self.call(guess, correct_label, circle_words)
    raise ArgumentError, "ANTHROPIC_API_KEY not configured" if ENV["ANTHROPIC_API_KEY"].blank? || ENV["ANTHROPIC_API_KEY"] == "your_api_key_here"

    client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])
    prompt = "The category label is: \"#{correct_label}\". The player guessed: \"#{guess}\". The words in this circle are: #{circle_words.join(", ")}. A correct guess must satisfy TWO conditions: (1) it is a synonym, paraphrase, or reasonable variation of the correct label, AND (2) the guessed word or phrase genuinely applies to ALL the words in the circle. Respond YES only if both conditions are met. Respond NO if the guess is a synonym of the label but doesn't actually describe all the words, or if it describes the words but isn't close enough to the label. Respond with only YES or NO."
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
