class AnthropicJudgeService
  def self.call(guess, correct_label, circle_words)
    raise ArgumentError, "ANTHROPIC_API_KEY not configured" if ENV["ANTHROPIC_API_KEY"].blank? || ENV["ANTHROPIC_API_KEY"] == "your_api_key_here"

    client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])
    prompt = "The correct category label is: \"#{correct_label}\". The player guessed: \"#{guess}\". Words in this circle include: #{circle_words.join(", ")}. Is the guess correct or close enough? Accept synonyms, paraphrases, and reasonable variations. Respond with only YES or NO."
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
