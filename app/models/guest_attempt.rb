GuestAttempt = Struct.new(:label, :guess, :correct, keyword_init: true) do
  def correct? = correct
end
