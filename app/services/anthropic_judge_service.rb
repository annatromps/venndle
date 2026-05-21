require "net/http"
require "uri"
require "json"

class AnthropicJudgeService
  MODEL = "gemini-flash-lite-latest"

  def self.call(guess, correct_label, circle_words)
    raise ArgumentError, "GEMINI_API_KEY not configured" if ENV["GEMINI_API_KEY"].blank?

    prompt = "The category label is: \"#{correct_label}\". The player guessed: \"#{guess}\". The words in this circle are: #{circle_words.join(", ")}.\n\nAccept the guess ONLY if both conditions are true:\n1. It is a synonym, word form (adjective/noun/adverb of the same root), or alternate spelling of the correct label.\n2. It genuinely and accurately describes ALL of the circle words listed — not just some of them.\n\nAccept: synonyms, plural/singular forms, adjective/noun/adverb variants of the same root word, common alternate spellings.\nReject: phrases that are only loosely related, overly broad statements, things that describe the concept in general but don't specifically fit all the circle words.\n\nRespond with only YES or NO."

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
