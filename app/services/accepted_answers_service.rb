require "net/http"
require "uri"
require "json"

class AcceptedAnswersService
  MODEL = "gemini-flash-latest"

  def self.call(label, words)
    raise ArgumentError, "GEMINI_API_KEY not configured" if ENV["GEMINI_API_KEY"].blank?

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

    text = gemini_request(prompt, max_tokens: 800)
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
