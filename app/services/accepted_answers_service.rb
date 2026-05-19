class AcceptedAnswersService
  def self.call(label, words)
    raise ArgumentError, "ANTHROPIC_API_KEY not configured" if ENV["ANTHROPIC_API_KEY"].blank? || ENV["ANTHROPIC_API_KEY"] == "your_api_key_here"

    client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])
    prompt = "The answer to a puzzle category is: \"#{label}\". The words in this circle are: #{words.join(', ')}. Generate a comprehensive list of all words and phrases a player might reasonably guess that should be accepted as correct. Include: exact answer, synonyms, noun/adjective/verb/adverb forms of the same root, informal versions, related concepts, more general or more specific versions that still fit all the circle words. Return ONLY a JSON array of strings, nothing else. Be generous — include anything a reasonable person might guess. Example format: [\"swimming\", \"swim\", \"swimmer\", \"aquatic\", \"water-based\", \"in water\"]"

    response = client.messages(
      parameters: {
        model: "claude-sonnet-4-20250514",
        max_tokens: 500,
        messages: [{ role: "user", content: prompt }]
      }
    )

    text = response.dig("content", 0, "text").to_s.strip
    # Strip markdown code fences if the model wraps output
    text = text.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
    JSON.parse(text).map { |s| s.to_s.downcase.strip }.uniq
  rescue => e
    Rails.logger.error "AcceptedAnswersService error: #{e.class}: #{e.message}"
    [label.to_s.downcase.strip]
  end
end
