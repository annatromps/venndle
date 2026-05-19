class GuestGameSession
  SESSION_KEY = "guest_game_sessions"

  def initialize(session, puzzle_id)
    @session = session
    @puzzle_id = puzzle_id.to_s
    @session[SESSION_KEY] ||= {}
    @session[SESSION_KEY][@puzzle_id] ||= default_data
  end

  def self.find_or_create(session, puzzle_id)
    new(session, puzzle_id)
  end

  def solved_a? = data["solved_a"]
  def solved_b? = data["solved_b"]
  def solved_c? = data["solved_c"]
  def completed? = data["completed"]
  def attempts_a = data["attempts_a"]
  def attempts_b = data["attempts_b"]
  def attempts_c = data["attempts_c"]

  def increment!(field)
    mutate { |d| d[field.to_s] = (d[field.to_s] || 0) + 1 }
  end

  def update!(attrs)
    mutate { |d| attrs.each { |k, v| d[k.to_s] = v } }
  end

  def reload = self

  private

  def data
    @session[SESSION_KEY][@puzzle_id]
  end

  def default_data
    {
      "solved_a" => false, "solved_b" => false, "solved_c" => false,
      "completed" => false,
      "attempts_a" => 0, "attempts_b" => 0, "attempts_c" => 0
    }
  end

  def mutate
    d = data.dup
    yield d
    all = @session[SESSION_KEY].dup
    all[@puzzle_id] = d
    @session[SESSION_KEY] = all
    self
  end
end
