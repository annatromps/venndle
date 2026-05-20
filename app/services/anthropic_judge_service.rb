require "net/http"
require "uri"
require "json"

class AnthropicJudgeService
  MODEL = "gemini-flash-lite-latest"

  def self.call(guess, correct_label, circle_words)
    raise ArgumentError, "GEMINI_API_KEY not configured" if ENV["GEMINI_API_KEY"].blank?

    prompt = "The category label is: \"#{correct_label}\". The player guessed: \"#{guess}\". The words in this circle are: #{circle_words.join(", ")}.\n\nA correct guess should be accepted if it is a synonym, related word, adjective/noun variation, or reasonable paraphrase of the correct label AND it genuinely applies to all the words in the circle. Be generous — accept:\n- Adjective/noun/adverb forms of the same root (round/rounded/spherical/sphere, sharp/sharpness, thin/thinness/skinny/slim/narrow)\n- Synonyms and near-synonyms\n- More specific or more general versions (e.g. 'metal' accepted for 'silver', 'colour' accepted for 'yellow things')\n- Informal or colloquial phrasings\n\nOnly reject if the guess is clearly wrong or describes something genuinely different. When in doubt, accept.\n\nRespond with only YES or NO."

    text = gemini_request(prompt, max_tokens: 10)
    text.strip.upcase.start_with?("YES")
  rescue => e
    Rails.logger.error "AnthropicJudgeService error: #{e.class}: #{e.message}"
    guess.strip.downcase == correct_label.to_s.strip.downcase
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
