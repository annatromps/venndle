# Create admin user
admin = User.find_or_create_by!(email: "admin@venndle.com") do |u|
  u.username = "admin"
  u.password = "password123"
  u.admin = true
end

# Sample daily puzzle: Animals / Colours / Round things
Puzzle.find_or_create_by!(title: "Animals, Colours & Round Things") do |p|
  p.user = admin
  p.puzzle_type = "daily"
  p.scheduled_date = Date.today
  p.published = true
  p.label_a = "Animals"
  p.label_b = "Colours"
  p.label_c = "Round things"
  p.words_a = ["wolf", "deer", "eagle"]
  p.words_b = ["indigo", "crimson", "teal"]
  p.words_c = ["wheel", "coin", "globe"]
  p.words_ab = ["flamingo", "raven", "goldfinch"]
  p.words_ac = ["pufferfish", "hedgehog", "armadillo"]
  p.words_bc = ["orange", "tomato"]
  p.words_abc = ["goldfish"]
end

puts "Seeded! Admin: admin@venndle.com / password123"
