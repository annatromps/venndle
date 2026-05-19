class AcceptedAnswersService
  def self.call(label, words)
    raise ArgumentError, "ANTHROPIC_API_KEY not configured" if ENV["ANTHROPIC_API_KEY"].blank? || ENV["ANTHROPIC_API_KEY"] == "your_api_key_here"

    client = Anthropic::Client.new(access_token: ENV["ANTHROPIC_API_KEY"])

    prompt = <<~PROMPT
      Generate every possible way a player might answer for the puzzle category "#{label}".
      The circle contains these words: #{words.join(", ")}.

      Return a JSON array including ALL of the following:
      - The exact answer "#{label}" itself
      - Every thesaurus synonym
      - All word forms: noun, verb, adjective, adverb (e.g. if label is "spherical" include: sphere, spheres, spherically, round, rounded, circular, globe, globular, ball-shaped, orb, orbicular, curved, bulbous)
      - Informal and colloquial versions
      - Singular and plural forms
      - Common misspellings or alternate spellings
      - Broader categories that still correctly describe all the circle words
      - Phrases that mean the same thing

      Return ONLY a valid JSON array of lowercase strings — no markdown, no explanation, no code fences.
      Be extremely generous. Aim for at least 20-30 entries. When in doubt, include it.
    PROMPT

    response = client.messages(
      parameters: {
        model: "claude-sonnet-4-20250514",
        max_tokens: 800,
        messages: [{ role: "user", content: prompt }]
      }
    )

    text = response.dig("content", 0, "text").to_s.strip
    text = text.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
    answers = JSON.parse(text).map { |s| s.to_s.downcase.strip }.reject(&:blank?).uniq

    Rails.logger.info "AcceptedAnswersService [#{label}]: #{answers.count} answers — #{answers.first(6).join(', ')}..."
    answers
  rescue => e
    Rails.logger.error "AcceptedAnswersService error for '#{label}': #{e.class}: #{e.message}"
    [label.to_s.downcase.strip]
  end
end
