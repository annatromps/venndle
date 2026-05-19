class AnthropicJudgeService
  def self.call(guess, correct_label, circle_words)
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
  end
end
