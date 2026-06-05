class Users::SessionsController < Devise::SessionsController
  def create
    request.params[:user] ||= {}
    request.params[:user][:remember_me] = "1"
    # Capture before Devise touches the session
    guest_sessions = (session["guest_game_sessions"] || {}).dup
    super
    transfer_guest_sessions(guest_sessions) if current_user && guest_sessions.any?
  end

  private

  def transfer_guest_sessions(guest_sessions)
    guest_sessions.each do |puzzle_id, data|
      next unless data["completed"]
      puzzle = Puzzle.find_by(id: puzzle_id)
      next unless puzzle
      next if GameSession.exists?(user: current_user, puzzle: puzzle)
      GameSession.create!(
        user:        current_user,
        puzzle:      puzzle,
        completed:   true,
        created_at:  puzzle.scheduled_date.to_time,
        solved_a:    data["solved_a"]    || false,
        solved_b:    data["solved_b"]    || false,
        solved_c:    data["solved_c"]    || false,
        attempts_a:  data["attempts_a"]  || 0,
        attempts_b:  data["attempts_b"]  || 0,
        attempts_c:  data["attempts_c"]  || 0,
        gave_up_a:   data["gave_up_a"]   || false,
        gave_up_b:   data["gave_up_b"]   || false,
        gave_up_c:   data["gave_up_c"]   || false,
        hint_used_a: data["hint_used_a"] || false,
        hint_used_b: data["hint_used_b"] || false,
        hint_used_c: data["hint_used_c"] || false,
        hints_a:     data["hints_a"]     || 0,
        hints_b:     data["hints_b"]     || 0,
        hints_c:     data["hints_c"]     || 0
      )
    end
  rescue => e
    Rails.logger.error "Guest session transfer failed: #{e.class}: #{e.message}"
  end
end
