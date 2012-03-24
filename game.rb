class Game
  attr_accessor :armor_list, :weapon_list, :equipment
  def initialize()
    #Game creates the city and mountain as two separate scenes
    @city = Scene.new("City", "The city.", @cm, @ls, "", self)
    @mountain = Scene.new("Mountain", "The mountain.", @em, @wh, @d, self)
    #Game creates armor and weapon array-name-holders, I couldn't find another way to make the equipment-selection work
    @a = Armor.new("armor_list", 0)
    @w = Weapon.new("weapon_list", 0)
    #Game creates weapons
    @ss = Weapon.new("Short sword", 5)
    @ls = Weapon.new("Long sword", 8)
    @ts = Weapon.new("Two-Handed sword", 12)
    @wh = Weapon.new("Warhammer", 10)
    #Game creates armors
    @la = Armor.new("Leather Armor", 5)
    @cm = Armor.new("Chain Mail", 10)
    @pm = Armor.new("Plate Mail", 15)
    @em = Armor.new("Elven Chain Mail", 50)
    #Game creates a hero and a dragon
    @h = Creature.new(name = "You", level = 5)
    @d = Creature.new(name = "Dragon", level = 12)
    #The default equipment list to provide an arsenal. I wish to separate them and put 1 or 2 into each scene
    @armor_list = [@a, @la, @cm, @pm, @em]
    @weapon_list = [@w, @ss, @ls, @ts, @wh]
    @equipment = []
  end

  def play()
    intro()
  end
  # If I can find a way to pass arguments between scenes and game, I'm going to put a variable 
  # to change the starting point. Otherwise I know that both intro() and play() is useless.
  def intro()
    @city.intro()
  end
end

class Creature
  attr_accessor :name, :life, :armor, :weapon, :regen
  def initialize(name, level)
    #Attributes accoridng to level and dice
    @name = name
    @level = level
    @equipment = {:armor => nil, :weapon => nil}
    @armor = 0
    @weapon = 0
    #3.times rand(7) or 3*rand(7) doesn't create the effect, I tried rand(16)+3 but didn't like it.
    @strength = rand(7) + rand(7) + rand(7)
    @condition = rand(7) + rand(7) + rand(7)
    @life = @level * (rand(8) + 1)
    @power = @strength * (rand(4) + 1)
    @regen = @condition
  end

  def select_equipment(equipment)
    introduce_self()
    selection(equipment)
    choice = gets.chomp.to_i
    #@a and @w help to get the name of the array, armor or weapon. 
    if equipment[0].name == "armor_list"
      wear_armor(equipment[choice])
    elsif equipment[0].name == "weapon_list"
      wear_weapon(equipment[choice])
    else
      raise ArgumentError, "Should be armor_list or weapon_list"
    end
    equipment.delete_at(choice)
  end

  def introduce_self()
    if @equipment[:armor] == nil
      puts "You wear no armor!"
    else
      puts "You wear #{@equipment[:armor]}."
    end
    if @equipment[:weapon] == nil
      puts "You carry no weapon!"
    else
      puts "You carry #{@equipment[:weapon]}."
    end 
  end
  
  def selection(equipment)
    puts "You wanna some equipment?"
    for i in (1..equipment.length-1) do
      puts "#{i}. #{equipment[i].name}"
      i += 1
    end
  end
  
  def wear_armor(armor)    
    @armor = armor.power
    @equipment[:armor] = armor.name
  end

  def wear_weapon(weapon)
    @weapon = weapon.power
    @equipment[:weapon] = weapon.name
  end

  def battle(opp1, opp2)
    #a basic round system depending on even and uneven numbers
    i = 1
    while opp1.life > 0 && opp2.life > 0
      if i % 2 == 0
        attack(opp1, opp2)
      elsif i % 2 == 1
        attack(opp2, opp1)
      else
        #just learning to raise errors, not into rescue, yet
        raise ArgumentError, "The battle is over!"
      end
      i += 1
      round_result(opp1, opp2)
    end
  end

  def round_result(opp1, opp2)
    puts "Hit points:"
    puts "#{opp1.name}: #{opp1.life}"
    puts "#{opp2.name}: #{opp2.life}"
  end

  def attack(attacker, defender)
    #this code below is just to prevent stuff like "hit with -27 points of damage"
    possible_attack = @power + @weapon - defender.armor
    if possible_attack > 0
      attack = possible_attack
    else
      attack = 0
    end
    defender.life -= attack
    puts "#{attacker.name} hit #{defender.name} with #{attack} points of damage!"
    if defender.life <= 0
      puts "...and killed!"
      defender.life = "Dead as cold stone!"
      round_result(attacker, defender)
      #game exits if one of the creatures die
      Process.exit(0)
    else
      defender.life += defender.regen
      puts "#{defender.name} regenerates #{defender.regen} points of life!"
    end
  end
end

#separate classes for weapons and armors, probably unnecessary but still learning
class Weapon
  attr_reader :name, :power
  def initialize(name, power)
    @name = name
    @power = power
  end
end

class Armor
  attr_reader :name, :power
  def initialize(name, power)
    @name = name
    @power = power
  end
end

# I want each scene have its own weapon or armor (scattered on the ground, maybe, according to the story..)
# but cannot achieve that with armors, weapon variables. The same thing applies to monsters. I would like
# to have for example rats and thieves in the city, but bats and a dragon in the mountain. However couldn't 
# achieve this exactly. So far I'm only successful in passing the game object to the scene object as the 
# last variable and I think that's a good start.
class Scene
  attr_reader :name, :history, :armors, :weapons, :monsters
  def initialize(name, history, armor_list, weapon_list, monsters, game)
    @name = name
    @history = history
    @armor_list ||= []
    @weapon_list ||= []
    @monsters ||= []
    @game = game
  end

  def intro()
    puts "You are in the " + @name + "."
    puts @history
    choices()
  end

  def choices()
    puts <<-CHOICES
    What would you like to do here?
    1. Look for armor
    2. Look for weapons
    3. Look for monsters to fight
    4. Go to another place!
    CHOICES
    choice = gets.chomp
    #this is where things go really bad! instance_variable_get saves the battle but as for the equipment selection,
    # as soon as I make a choice, it throws this error:
    # "game.rb:193:in 'choices': #<Armor:0x429720 @name="....> is not a symbol (TypeError)" 
    # and I don't think that further addition of : or @ is needed here.
    #The solution should be much simpler but couldn't find it on the web.
    if choice == "1"
      @game.send(@game.instance_variable_get(:@h).select_equipment(@game.instance_variable_get(:@armor_list)))
    elsif choice == "2"
      @game.send(@game.instance_variable_get(:@h).select_equipment(@game.instance_variable_get(:@weapon_list)))
    elsif choice == "3"
      @game.send(@game.instance_variable_get(:@h).battle(@game.instance_variable_get(:@h), @game.instance_variable_get(:@d)))
    elsif choice == "4"
      puts "Fuck you!"
    else
      puts "Can't you read?"
    end
  end

  #this is just to show the player a list of equipment found in the scene.
  def equipment_list()
    @armor_list[1..@armor_list.length-1].each {|a| @equipment.push(a.name) }
    @weapon_list[1..@weapon_list.length-1].each {|w| @equipment.push(w.name) }
    puts "You see some #{@room_equipment.join(", ")} lying on the ground."
  end
end

game = Game.new()
game.play()
