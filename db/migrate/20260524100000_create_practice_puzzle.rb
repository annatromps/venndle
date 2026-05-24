class CreatePracticePuzzle < ActiveRecord::Migration[8.0]
  def up
    return if Puzzle.exists?(puzzle_type: "practice")

    admin = User.find_by(admin: true) || User.first
    return unless admin

    Puzzle.create!(
      puzzle_type:        "practice",
      title:              "Bed linen",
      published:          true,
      user:               admin,
      label_a:            "flat",
      label_b:            "white",
      label_c:            "sheet",
      words_a:            ["apartment"],
      words_b:            ["snow"],
      words_c:            ["excel"],
      words_ab:           ["coffee"],
      words_ac:           ["paper"],
      words_bc:           ["ghost"],
      words_abc:          ["bed linen"],
      accepted_answers_a: ["flat"],
      accepted_answers_b: ["white"],
      accepted_answers_c: ["sheet"]
    )
  end

  def down
    Puzzle.where(puzzle_type: "practice").destroy_all
  end
end
