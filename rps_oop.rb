require 'yaml'

module Write
  MESSAGES = YAML.load_file('rps.yml')

  def self.prompt(message)
    puts "=> #{message}"
  end

  def self.messages(message)
    MESSAGES[message]
  end
end

module RPSGameDisplay
  include Write

  def display_name_and_opponent
    Write.prompt format(Write.messages('welcome_name'), human_name: human.name)
    Write.prompt format(Write.messages('points_to_win'))
    Write.prompt format(Write.messages('your_opponent'), name: computer.name)
  end

  def display_welcome_message
    display_name_and_opponent
    Write.prompt format(Write.messages('need_rules'))
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
    puts format(Write.messages('rules'))
    Write.prompt format(Write.messages('player_clear_screen'))
    loop do
      user_input = gets.chomp
      break if user_input.downcase == 'c'
      Write.prompt format(Write.messages('computer_angry'))
    end
    system "clear"
  end

  def display_moves
    Write.prompt format(Write.messages('human_move'), human_name: human.name,
                                                      human_move: human.move)
    Write.prompt format(Write.messages('computer_move'), name: computer.name,
                                                         move: computer.move)
  end

  def display_round_winner
    human_move = human.move
    computer_move = computer.move
    if human_move > computer_move
      Write.prompt format(Write.messages('human_won_round'), name: human.name)
    elsif human_move < computer_move
      Write.prompt format(Write.messages('computer_won'), name: computer.name)
    else
      Write.prompt format(Write.messages('its_a_tie'))
    end
  end

  def display_current_score
    Write.prompt format(Write.messages('human_score'), human_name: human.name,
                                                       human_score: human.score)
    Write.prompt format(Write.messages('computer_score'), name: computer.name,
                                                          score: computer.score)
    Write.prompt format(Write.messages('separation_banner'))
  end

  def display_human_win
    Write.prompt format(Write.messages('human_wins_game'), name: human.name)
    Write.prompt format(Write.messages('separation_banner'))
  end

  def display_computer_win
    Write.prompt format(Write.messages('comp_win_game'), name: computer.name)
    Write.prompt format(Write.messages('separation_banner'))
  end

  def display_game_winner
    if human.score == 8
      display_human_win
      Write.prompt format(computer.personality.losing_message)
    elsif computer.score == 8
      display_computer_win
      Write.prompt format(computer.personality.winning_message)
    end
    Write.prompt format(Write.messages('separation_banner'))
  end

  def optional_display_move_history(human, computer)
    Write.prompt format(Write.messages('want_move_history?'))
    answer = gets.chomp
    return display_move_history(human, computer) if answer.start_with?('y')
  end

  def display_move_history(human, computer)
    Write.prompt format(Write.messages('human_move_history'))
    p human.move_history
    puts format(Write.messages('line_break'))
    Write.prompt format(Write.messages('computer_move_history'))
    p computer.move_history
    Write.prompt format(Write.messages('separation_banner'))
  end

  def display_goodbye_message
    Write.prompt format(Write.messages('thanks'), human_name: human.name)
  end
end

class Player
  attr_accessor :move, :name
  attr_reader :score

  include Write

  def initialize
    @score = 0
  end

  def add_point
    self.score += 1
  end

  def score_reset
    self.score = 0
  end

  private

  attr_writer :score
end

class Human < Player
  def initialize
    set_name
    super
    @human_move_history = []
  end

  def set_name
    name = ''
    loop do
      Write.prompt format(Write.messages('welcome'))
      name = gets.chomp
      break unless name.strip.delete('^A-Za-z').empty?
      Write.prompt format(Write.messages('valid_name'))
    end
    system "clear"
    self.name = name.capitalize
  end

  def prompt_choice
    puts format(Write.messages('line_break'))
    Write.prompt format(Write.messages('pick_move'))
  end

  def choose
    choice = nil
    loop do
      prompt_choice
      choice = gets.chomp
      break if Move::WINNING_COMBOS.keys.include? choice
      Write.prompt format(Write.messages('valid_move'))
    end
    self.move = Move.new(choice)
    @human_move_history << move.value
  end

  def move_history
    @human_move_history
  end
end

class Personality
  attr_accessor :name, :moves, :losing_message, :winning_message

  def initialize(name, moves, losing_message, winning_message)
    @name = name
    @moves = moves
    @losing_message = losing_message
    @winning_message = winning_message
  end

  CLAPTRAP_MOVES = %w(rock spock lizard lizard lizard)
  # not a very clever guy, just loves lizards
  MRGUTSY_MOVES = %w(scissors rock rock rock)
  # wants to crush other life forms with rock
  MRHANDY_MOVES = %w(rock scissors paper paper paper)
  # intellectual opponent, believes the pen is mightier than the sword

  def display_loser_message
    self.losing_message
  end

  def display_winner_message
    self.winning_message
  end 
end

class Computer < Player
  attr_reader :personality

  CLAPTRAP = Personality.new("Claptrap",
                            %w(rock spock lizard lizard lizard),
                            Write.messages('claptrap_lost'),
                            Write.messages('claptrap_won'))
  MR_HANDY = Personality.new("Mr. Handy",
                            %w(rock scissors paper paper paper),
                            Write.messages('mr_handy_lost'),
                            Write.messages('mr_handy_won'))
  MR_GUTSY = Personality.new("Mr. Gutsy",
                            %w(scissors rock rock rock),
                            Write.messages('mr_gutsy_lost'),
                            Write.messages('mr_gutsy_won'))

  def initialize
    super
    @personality = [CLAPTRAP, MR_HANDY, MR_GUTSY].sample
    @computer_move_history = []
  end

  def name #overriding parent getter
    @personality.name 
  end

  def choose
    self.move = Move.new(personality.moves.sample)
    @computer_move_history << move.value
  end

  def move_history
    @computer_move_history
  end
end

class Move
  attr_accessor :value

  include Comparable

  WINNING_COMBOS = {
    'rock' => %w(lizard scissors),
    'paper' => %w(rock spock),
    'scissors' => %w(lizard paper),
    'lizard' => %w(spock paper),
    'spock' => %w(rock scissors)
  }

  def initialize(value)
    @value = value
  end

  def <=>(other)
    if WINNING_COMBOS[value].include?(other.value)
      1
    elsif WINNING_COMBOS[other.value].include?(value)
      -1
    else
      0
    end
  end

  def to_s
    @value
  end
end

class RPSGame
  attr_accessor :human, :computer

  include RPSGameDisplay
  include Write

  def play
    play_game
  end

  def initialize
    @computer = Computer.new
  end

  private

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
      Write.prompt format(Write.messages('play_again?'))
      answer = gets.chomp
      break if %w(y n).include?(answer)
      Write.prompt format(Write.messages('valid_answer'))
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
    optional_display_move_history(human, computer)
  end

  def play_game
    @human = Human.new
    display_welcome_message
    loop do
      play_round
      display_game_winner
      break unless play_again?
      human.score_reset
      computer.score_reset
    end
    display_goodbye_message
  end
end

RPSGame.new.play
