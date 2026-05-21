require "net/http"
require "uri"
require "json"

class AcceptedAnswersService
  MODEL = "gemini-flash-lite-latest"

  def self.call(label, words)
    raise ArgumentError, "GEMINI_API_KEY not configured" if ENV["GEMINI_API_KEY"].blank?

    prompt = <<~PROMPT
      You are generating accepted answers for a Venn diagram word puzzle.

      The circle label (correct answer) is: "#{label}"
      The words inside this circle are: #{words.join(", ")}

      Generate every reasonable way a player might type this answer. Include:
      - The exact label itself
      - Synonyms and near-synonyms of the label
      - All word forms: singular, plural, adjective, noun, adverb forms of the same root word
      - Common alternate spellings or misspellings

      CRITICAL RULE: Every entry you include MUST genuinely and accurately describe ALL of the circle words listed above — not just some of them. If a word or phrase only loosely applies, or applies to the concept in general but not specifically to these words, do NOT include it.

      Example of what NOT to do: if the label is "Big" and the circle contains "Elephant, Mountain, Ocean", do NOT include phrases like "the whole world" or "everything" — those don't specifically describe those words. DO include: big, large, huge, enormous, massive, giant, gigantic, colossal, vast, immense, great, sizable.

      Return ONLY a valid JSON array of lowercase strings. No markdown, no explanation, no code fences.
    PROMPT

    text = gemini_request(prompt, max_tokens: 600)
    text = text.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
    answers = JSON.parse(text).map { |s| s.to_s.downcase.strip }.reject(&:blank?).uniq

    Rails.logger.info "AcceptedAnswersService [#{label}]: #{answers.count} answers — #{answers.first(6).join(', ')}..."
    answers
  rescue => e
    Rails.logger.error "AcceptedAnswersService error for '#{label}': #{e.class}: #{e.message}"
    [label.to_s.downcase.strip]
  end

  def self.gemini_request(prompt, max_tokens: 256, retries: 3)
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{MODEL}:generateContent?key=#{ENV['GEMINI_API_KEY']}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 30

    req = Net::HTTP::Post.new(uri)
    req["Content-Type"] = "application/json"
    req.body = JSON.generate({
      contents: [ { parts: [ { text: prompt } ] } ],
      generationConfig: { maxOutputTokens: max_tokens }
    })

    retries.times do |attempt|
      res = http.request(req)
      data = JSON.parse(res.body)

      if res.code == "429" || data["error"]&.dig("code") == 429
        wait = 2 ** attempt
        Rails.logger.warn "Gemini rate limited, retrying in #{wait}s (attempt #{attempt + 1}/#{retries})"
        sleep wait
        next
      end

      text = data.dig("candidates", 0, "content", "parts", 0, "text")
      if text.nil?
        Rails.logger.error "Gemini unexpected response (status #{res.code}): #{res.body.first(500)}"
        return ""
      end

      return text.to_s.strip
    end

    ""
  end
end
