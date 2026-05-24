require "net/http"
require "uri"
require "json"

class AcceptedAnswersService
  MODEL = "gemini-flash-lite-latest"

  def self.call(label, words, all_puzzle_words = [])
    raise ArgumentError, "GEMINI_API_KEY not configured" if ENV["GEMINI_API_KEY"].blank?

    puzzle_words_clause = all_puzzle_words.any? ? "\n      ABSOLUTE RULE — NEVER INCLUDE PUZZLE WORDS: The following words are the actual puzzle words. NEVER include any of them (or their inflections) as an accepted answer, no matter how related they seem: #{all_puzzle_words.join(", ")}." : ""

    prompt = <<~PROMPT
      You are generating accepted answers for a Venn diagram word puzzle.

      The circle label (correct answer) is: "#{label}"
      The words inside this circle are: #{words.join(", ")}
      #{puzzle_words_clause}
      Generate every reasonable way a player might type this answer. Include:
      - The exact label itself
      - Synonyms and near-synonyms of the label
      - All word forms: singular, plural, adjective, noun, adverb forms of the same root word
      - Common alternate spellings or misspellings
      - If the label is a compound phrase (e.g. "music genres", "animal types", "colour names"), also include the primary noun alone (e.g. "music", "animals", "colours") — but only if that word genuinely and accurately describes ALL the circle words

      CRITICAL RULE — ALL WORDS MUST PASS: Before including any variation, mentally test it against EVERY circle word individually. A variation is only acceptable if it accurately describes or applies to EACH AND EVERY word in the circle. If even one word does not fit, exclude the variation entirely.

      WORKED EXAMPLE OF THIS RULE:
      Label = "white", circle words = ghost, snow, coffee, paper, bed linen
      - "pale" → REJECT. Pale ghost ✓, pale snow ✓, but pale coffee ✗ (coffee is not pale), pale paper ✗ (paper is not pale). Fails on 2 words — exclude.
      - "light-coloured" → REJECT. Same problem — coffee and paper are not light-coloured in the way "white" means here.
      - "ivory" → REJECT. Ghost is not ivory; snow is not ivory.
      - "white" ✓, "whites" ✓, "whitish" ✓ — these describe all five words accurately.

      Apply this same per-word test to every candidate before including it.

      Return ONLY a valid JSON array of lowercase strings. No markdown, no explanation, no code fences.
    PROMPT

    text = gemini_request(prompt, max_tokens: 600)
    text = text.gsub(/\A```(?:json)?\n?/, "").gsub(/\n?```\z/, "").strip
    blocked = all_puzzle_words.map(&:downcase)
    answers = JSON.parse(text).map { |s| s.to_s.downcase.strip }.reject(&:blank?).uniq
    answers = answers.reject { |a| blocked.include?(a) }

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
