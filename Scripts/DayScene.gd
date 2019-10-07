extends Node2D

onready var walker_res = load("res://Actors/Walker.tscn")
onready var skewer_res = load("res://Actors/Skewer.tscn")
onready var money_res = load("res://Actors/Money.tscn")
onready var nugget_brain_res = load("res://Actors/NuggetBrain.tscn")

onready var transition_res = load("res://Interface/Transition.tscn")
onready var end_day_button_res = load("res://Interface/EndDayButton.tscn")

onready var walker_timer = Timer.new()
onready var end_minigame_timer = Timer.new()

var fading_out = false

var current_customer: Node2D
var customer_chance = 2 / 10.0

var minigame_result

func _ready():
	Global.money_today = 0
	
	walker_timer.name = "WalkerTimer"
	walker_timer.autostart = true
	walker_timer.one_shot = false
	walker_timer.connect("timeout", self, "_on_walker_timer_timeout")
	walker_timer.start(1.4)
	add_child(walker_timer)
	
	end_minigame_timer.name = "EndMinigameTimer"
	end_minigame_timer.autostart = false
	end_minigame_timer.one_shot = true
	end_minigame_timer.connect("timeout", self, "_on_end_minigame_timer_timeout")
	add_child(end_minigame_timer)
	
	var t = transition_res.instance()
	t.get_node('AnimationPlayer').play('fade_in')
	$CanvasLayer.add_child(t)
	
	Global.connect("EndDayButton", self, "change_scene")
	Global.connect("Attract", self, "_attract")

func _on_walker_timer_timeout():
	var walker = walker_res.instance()
	walker.stand_position = get_random_area_position($StandArea)
	
	if randi() % 2 == 0:
		walker.global_position = get_random_area_position($LeftArea)
		walker.exit_position = get_random_area_position($RightArea)
	else:
		walker.global_position = get_random_area_position($RightArea)
		walker.exit_position = get_random_area_position($LeftArea)
	
	if randf() < customer_chance:
		walker.customer = true
	
	$Walkers.add_child(walker)

func start_minigame(customer: Node2D):
	current_customer = customer
	
	var skewer = skewer_res.instance()
	skewer.position = Vector2(-20, 167)
	add_child(skewer)
	
	var nugget_brain = nugget_brain_res.instance()
	nugget_brain.position = Vector2(320, 150)
	add_child(nugget_brain)

func minigame_tap(minigame_result):
	var result_count = minigame_result['Good'] + minigame_result['Bad']
	var nugget_count = 5 if Global.has_more_chicken else 4
	if result_count == nugget_count and $EndMinigameTimer.is_stopped(): 
		self.minigame_result = minigame_result
		$EndMinigameTimer.start(.5)
	
func _on_end_minigame_timer_timeout():
	var reward: int
	match minigame_result['Good']:
		0: reward = 0
		1: reward = 50
		2: reward = 100
		3: reward = 200
		4: reward = 400
		5: reward = 500
	
	Global.money_today += reward
	
	var money = money_res.instance()
	money.amount = reward
	money.position.x = 200 + (randi() % 100)
	money.position.y = 100 + (randi() % 100)
	add_child(money)
	
	if Global.has_tip_jar:
		var money2 = money_res.instance()
		money2.is_tip = true
		money2.position = $TipJar.position
		if randi() % 3 == 0:
			money2.amount = 25 + (randi() % 176)
		
		add_child(money2)
	
	current_customer.bought = true
	current_customer = null
	
	customer_chance += rand_range(0.01, 0.05)
	if customer_chance > 0.3: customer_chance = 0.3
	
	#free_nodes(["Skewer", "NuggetBrain", "Nugget1", "Nugget2", "Nugget3", "Nugget4"])
	free_nodes(["Skewer", "NuggetBrain"])

func free_nodes(node_names):
	for node_name in node_names:
		get_node(node_name).queue_free()

func stop_spawning():
	$WalkerTimer.stop()
	
	var button: Button = end_day_button_res.instance()
	button.rect_position = Vector2(245, 410)
	add_child(button)

func get_random_area_position(area: Area2D) -> Vector2:
	var center = area.get_node('CollisionShape2D').position
	var size = area.get_node('CollisionShape2D').shape.extents
	
	var stand_position = Vector2.ZERO
	stand_position.x = (randi() % int(size.x)) - (size.x / 2) + center.x
	stand_position.y = (randi() % int(size.y)) - (size.y / 2) + center.y
	return stand_position

func _attract():
	var num_to_attract = 1 + (randi() % 3)
	
	var walkers = $Walkers.get_children().duplicate()
	walkers.shuffle()
	
	for walker in walkers:
		if not walker.customer:
			walker.customer = true
			walker.modulate.g = 255
			
			num_to_attract -= 1
			if num_to_attract == 0: break

func change_scene():
	if not fading_out:
		fading_out = true
		
		var t = transition_res.instance()
		t.get_node('AnimationPlayer').play('fade_out')
		t.get_node('AnimationPlayer').connect('animation_finished', self, '_change_scene')
		$CanvasLayer.add_child(t)

func _change_scene(unused):
	Global.day += 1
	Global.money_acc += Global.money_today
	get_tree().change_scene("res://Scenes/DayEndScene.tscn")
