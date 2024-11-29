require 'yaml'
MESSAGES = YAML.load_file('rps.yml')

module Writable
  def prompt(message)
    puts "=> #{message}"
  end

  def messages(message)
    MESSAGES[message]
  end
end

module Displayable
  include Writable

  def display_name_and_opponent
    prompt format(messages('welcome_name'), human_name: human.name)
    prompt format(messages('points_to_win'))
    prompt format(messages('your_opponent'), computer_name: computer.name)
  end

  def display_welcome_message
    display_name_and_opponent
    prompt format(messages('need_rules'))
    answer = gets.chomp
    want_rules?(answer)
  end

  def want_rules?(answer)
    if %w(y yes).include?(answer.downcase)
      display_rules
    else
      system "clear"
    end
  end

  def display_rules
    puts format(messages('rules'))
    prompt format(messages('player_clear_screen'))
    loop do
      user_input = gets.chomp
      break if user_input.downcase == 'c'
      prompt format(messages('computer_angry'))
    end
    system "clear"
  end

  def display_goodbye_message
    prompt format(messages('thanks_for_playing'), human_name: human.name)
  end

  def display_moves
    prompt format(messages('human_move'), human_name: human.name,
                                          human_move: human.move)
    prompt format(messages('computer_move'), computer_name: computer.name,
                                             computer_move: computer.move)
  end

  # rubocop:disable Metrics/AbcSize
  def display_round_winner
    if human.move > computer.move
      prompt format(messages('human_won_round'), human_name: human.name)
    elsif human.move < computer.move
      prompt format(messages('computer_won'), computer_name: computer.name)
    else
      prompt format(messages('its_a_tie'))
    end
  end
  # rubocop:enable Metrics/AbcSize

  def display_current_score
    prompt format(messages('human_score'), human_name: human.name,
                                           human_score: human.score)
    prompt format(messages('computer_score'), computer_name: computer.name,
                                              computer_score: computer.score)
    prompt format(messages('separation_banner'))
  end

  def display_human_win
    prompt format(messages('human_wins_game'), human_name: human.name)
    prompt format(messages('separation_banner'))
  end

  def display_computer_win
    prompt format(messages('computer_win_game'), computer_name: computer.name)
    prompt format(messages('separation_banner'))
  end

  def display_game_winner(player_score, computer_score)
    if player_score == 8
      display_human_win
      computer.display_loser_message(computer.name)
    elsif computer_score == 8
      display_computer_win
      computer.display_winner_message(computer.name)
    end
    prompt format(messages('separation_banner'))
  end

  def display_move_history(human, computer)
    prompt format(messages('human_move_history'))
    p human.move_history
    puts format(messages('line_break'))
    prompt format(messages('computer_move_history'))
    p computer.move_history
    prompt format(messages('separation_banner'))
  end

  def display_loser_message(name)
    case name
    when 'Claptrap'
      prompt format(messages('claptrap_lost'))
    when 'Mr. Handy'
      prompt format(messages('mr_handy_lost'))
    when 'Mr. Gutsy'
      prompt format(messages('mr_gutsy_lost'))
    end
  end

  def display_winner_message(name)
    case name
    when 'Claptrap'
      prompt format(messages('claptrap_won'))
    when 'Mr. Handy'
      prompt format(messages('mr_handy_won'))
    when 'Mr. Gutsy'
      prompt format(messages('mr_gutsy_won'))
    end
  end
end

class Player
  attr_accessor :move, :name, :score

  include Displayable

  def initialize
    set_name
    @score = 0
  end

  def add_point
    self.score += 1
  end

  def score_reset
    self.score = 0
  end
end

class Human < Player
  @@human_move_history = []

  def set_name
    name = ''
    loop do
      prompt format(messages('welcome'))
      name = gets.chomp
      break unless name.strip.empty?
      prompt format(messages('valid_name'))
    end
    system "clear"
    self.name = name.capitalize
  end

  def prompt_choice
    puts format(messages('line_break'))
    prompt format(messages('pick_move'))
  end

  def choose
    choice = nil
    loop do
      prompt_choice
      choice = gets.chomp
      break if Move::WINNING_COMBOS.keys.include? choice
      prompt format(messages('valid_move'))
    end
    self.move = Move.new(choice)
    @@human_move_history << move.value
  end

  def move_history
    @@human_move_history
  end
end

class Computer < Player
  @@computer_move_history = []

  def set_name
    self.name = ['Claptrap', 'Mr. Handy', 'Mr. Gutsy'].sample
  end

  def choose
    if @name == 'Claptrap'
      self.move = Move.new(Move::CLAPTRAP_MOVES.sample)
    elsif @name == 'Mr. Handy'
      self.move = Move.new(Move::MRHANDY_MOVES.sample)
    elsif @name == 'Mr. Gutsy'
      self.move = Move.new(Move::MRGUTSY_MOVES.sample)
    end
    @@computer_move_history << move.value
  end

  def move_history
    @@computer_move_history
  end
end

class Move
  attr_accessor :value

  WINNING_COMBOS = {
    'rock' => %w(lizard scissors),
    'paper' => %w(rock spock),
    'scissors' => %w(lizard paper),
    'lizard' => %w(spock paper),
    'spock' => %w(rock scissors)
  }

  CLAPTRAP_MOVES = %w(rock spock lizard lizard lizard)
  # not a very clever guy, just loves lizards
  MRGUTSY_MOVES = %w(scissors rock rock rock)
  # wants to crush other life forms with rock
  MRHANDY_MOVES = %w(rock scissors paper paper paper)
  # intellectual opponent, believes the pen is mightier than the sword

  def initialize(value)
    @value = value
  end

  def >(other)
    WINNING_COMBOS[value].include?(other.value)
  end

  def <(other)
    WINNING_COMBOS[other.value].include?(value)
  end

  def to_s
    @value
  end
end

class RPSGame
  attr_accessor :human, :computer

  include Displayable

  def initialize
    @human = Human.new
    @computer = Computer.new
  end

  def update_score
    if human.move > computer.move
      human.add_point
    elsif human.move < computer.move
      computer.add_point
    end
    display_current_score
  end

  def play_again?
    answer = nil
    loop do
      prompt format(messages('play_again?'))
      answer = gets.chomp
      break if %w(y n).include?(answer)
      prompt format(messages('valid_answer'))
    end

    return true if answer.downcase == 'y'
    return false if answer.downcase == 'n'
  end

  def winning_score?(player_score, computer_score)
    player_score >= 8 || computer_score >= 8
  end

  def play_round
    loop do
      human.choose
      computer.choose
      display_moves
      display_round_winner
      update_score
      break if winning_score?(human.score, computer.score)
    end
    display_move_history(human, computer)
  end

  def play_game
    display_welcome_message
    loop do
      play_round
      display_game_winner(human.score, computer.score)
      break unless play_again?
      human.score_reset
      computer.score_reset
    end
    display_goodbye_message
  end
end

RPSGame.new.play_game
