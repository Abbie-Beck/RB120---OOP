require 'yaml'

module ClearScreen
  def self.clear
    (system 'clear') || (system 'cls')
  end
end

module Write
  MESSAGES = YAML.load_file('oop_twenty_one_messages.yml')

  def self.prompt(message)
    puts "=> #{message}"
  end

  def self.messages(message)
    MESSAGES[message]
  end

  def self.formatted_prompt(message)
    prompt format(messages(message))
  end
end

module Displayable
  def display_welcome_message
    Write.formatted_prompt('welcome')
  end

  def display_opponent
    Write.prompt format(Write.messages('your_opponent'), name: dealer.name)
  end

  def need_rules?
    Write.formatted_prompt('need_rules')
    answer = gets.chomp
    want_rules?(answer)
  end

  def rules
    Write.formatted_prompt('rules')
    loop do
      Write.formatted_prompt('done_with_rules')
      answer = gets.chomp.downcase
      return ClearScreen.clear if %w(p play).include?(answer)
      Write.formatted_prompt('press_p')
    end
  end

  def want_rules?(answer)
    %w(y yes).include?(answer.downcase) ? rules : ClearScreen.clear
  end

  def player_busted_message
    Write.prompt format(Write.messages('busted'), name1: player.name,
                                                  name2: dealer.name)
    dealer.show_hand
  end

  def dealer_busted_message
    Write.prompt format(Write.messages('busted'), name1: dealer.name,
                                                  name2: player.name)
  end

  def show_busted
    if player.busted?
      player_busted_message

    elsif dealer.busted?
      dealer_busted_message
    end
  end

  def show_hands
    player.show_cards
    dealer.show_cards
  end

  def player_wins_message
    Write.prompt format(Write.messages('winner'), name: player.name)
  end

  def dealer_wins_message
    Write.prompt format(Write.messages('winner'), name: dealer.name)
  end

  def tie_message
    Write.formatted_prompt('tie')
  end

  def show_result
    if player.total > dealer.total
      player_wins_message
    elsif player.total < dealer.total
      dealer_wins_message
    else
      tie_message
    end
  end

  def play_again?
    answer = nil
    loop do
      Write.formatted_prompt('play_again')
      answer = gets.chomp.downcase
      return true if %(y yes).include?(answer)
      return false if %w(n no).include?(answer)
      Write.formatted_prompt('valid_response')
    end
  end

  def show_final_results
    show_hands
    show_result
  end
end

module Hand
  include Write
  
  MAX_SCORE = 21

  def court_card?(card)
    card.jack? || card.queen? || card.king?
  end

  def total
    total = 0
    cards.each do |card|
      total += card.score
    end

    cards.select(&:ace?).count.times do
      break if total <= MAX_SCORE
      total -= 10
    end

    total
  end

  def add_card(new_card)
    cards << new_card
  end

  def busted?
    total > MAX_SCORE
  end
end

class Card
  include Write

  SUITS = ['♠', '♥', '♦', '♣']
  FACES = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']

  RED = "\e[31m"
  BLACK = "\e[37m"
  RESET = "\e[0m"

  def color
    ['♥', '♦'].include?(@suit) ? Card::RED : Card::BLACK
  end

  def display_pretty_card
    [
      "┌─────────┐",
      "│#{color}#{@face.ljust(2)}       #{Card::RESET}│",
      "│         │",
      "│#{color}    #{@suit}    #{Card::RESET}│",
      "│         │",
      "│#{color}       #{@face.rjust(2)}#{Card::RESET}│",
      "└─────────┘"
    ].join("\n")
  end

  def initialize(suit, face)
    @suit = suit
    @face = face
  end

  def to_s
    Write.prompt format(Write.messages('output_card'), face: face, suit: suit)
  end

  def face
    case @face
    when 'J' then 'Jack'
    when 'Q' then 'Queen'
    when 'K' then 'King'
    when 'A' then 'Ace'
    else
      @face
    end
  end

  def score
    if jack? || queen? || king?
      10
    elsif ace?
      11
    else
      face.to_i
    end
  end

  def suit
    {
      'H' => 'Hearts',
      'D' => 'Diamonds',
      'S' => 'Spades',
      'C' => 'Clubs'
    }
  end

  def ace?
    face == 'Ace'
  end

  def king?
    face == 'King'
  end

  def queen?
    face == 'Queen'
  end

  def jack?
    face == 'Jack'
  end
end

class Deck
  attr_accessor :cards

  def initialize
    @cards = []
    Card::SUITS.each do |suit|
      Card::FACES.each do |face|
        @cards << Card.new(suit, face)
      end
    end

    scramble!
  end

  def scramble!
    cards.shuffle!
  end

  def deal_one
    cards.pop
  end
end

class Participant
  include Hand

  attr_accessor :name, :cards

  def initialize
    @cards = []
  end

  COLOR = "\e[37m"
  RESET = "\e[0m"

  def display_mystery_card
    marker = "?"
    [
      "┌─────────┐",
      "│#{COLOR}#{marker.ljust(2)}       #{Card::RESET}│",
      "│         │",
      "│#{COLOR}    #{marker}    #{Card::RESET}│",
      "│         │",
      "│#{COLOR}       #{marker.rjust(2)}#{Card::RESET}│",
      "└─────────┘"
    ].join("\n")
  end

  def show_initial_cards
    Write.prompt format(Write.messages('show_hand'), name: name)
    puts cards.first.display_pretty_card
    puts display_mystery_card
    puts ""
  end

  def show_hand
    Write.prompt format(Write.messages('show_hand'), name: name)
    cards.each do |card|
      puts card.display_pretty_card
    end
    Write.prompt format(Write.messages('show_total'), total: total)
    puts ""
  end

  def show_cards
    show_hand
  end
end

class Player < Participant
  def set_name
    name = ''
    loop do
      Write.formatted_prompt('input_name')
      name = gets.chomp.capitalize
      break unless name.strip.empty?
      Write.formatted_prompt('valid_name')
    end
    self.name = name
  end
end

class Dealer < Participant
  DEALERS = %w(Cooper Laura Donna James Bobby Audrey)
  def initialize
    super
    set_name
  end

  def set_name
    self.name = DEALERS.sample
  end
end

class TwentyOne
  include Write
  include Displayable

  def initialize
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def play_game
    start
  end

  private

  attr_accessor :deck, :player, :dealer

  def reset
    self.deck = Deck.new
    player.cards = []
    dealer.cards = []
  end

  def deal_cards
    player.cards << deck.deal_one << deck.deal_one
    dealer.cards << deck.deal_one << deck.deal_one
  end

  def show_cards
    player.show_cards
    dealer.show_initial_cards
  end

  def player_hits
    player.add_card(deck.deal_one)
    Write.prompt format(Write.messages('hits'), name: player.name)
    player.show_hand
  end

  def hit_or_stay?
    answer = nil
    loop do
      answer = gets.chomp.downcase
      return answer if %w(h hit s stay).include?(answer)
      Write.formatted_prompt('valid_hit_or_stay')
    end
  end

  def aquire_hit_or_stay
    Write.formatted_prompt('hit_or_stay')
    hit_or_stay?
  end

  def player_stays_message
    Write.prompt format(Write.messages('stays'), name: player.name)
  end

  def player_turn_loop
    loop do
      if %w(s stay).include?(aquire_hit_or_stay)
        return player_stays_message
      elsif player.busted?
        break
      else
        player_hits
        break if player.busted?
      end
    end
  end

  def player_turn
    Write.prompt format(Write.messages('turn'), name: player.name)
    player_turn_loop
  end

  def dealer_hits
    Write.prompt format(Write.messages('hits'), name: dealer.name)
    dealer.add_card(deck.deal_one)
    player.show_cards
    dealer.show_cards
  end

  def dealer_stays
    Write.prompt format(Write.messages('stays'), name: dealer.name)
  end

  def dealer_turn_loop
    loop do
      if dealer.total >= 17 && !dealer.busted?
        dealer_stays
        break
      elsif dealer.busted?
        break
      else
        dealer_hits
      end
    end
  end

  def dealer_turn
    Write.prompt format(Write.messages('turn'), name: dealer.name)
    dealer_turn_loop
  end

  def start
    display_welcome_message
    display_opponent
    need_rules?
    player.set_name
    loop do
      play_single_game
      break unless play_again?
      reset
    end
    Write.formatted_prompt('goodbye')
  end

  def play_single_game
    setup_game
    player_turn
    return if player_busted?
    dealer_turn
    return if dealer_busted?
    show_final_results
  end

  def setup_game
    ClearScreen.clear
    deal_cards
    show_cards
  end

  def player_busted?
    if player.busted?
      show_busted
      true
    else
      false
    end
  end

  def dealer_busted?
    if dealer.busted?
      show_busted
      true
    else
      false
    end
  end
end

game = TwentyOne.new
game.play_game
