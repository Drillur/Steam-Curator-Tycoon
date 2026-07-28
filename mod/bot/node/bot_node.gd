# class_name BotNode
extends MarginContainer

static var main: Node
static var bots: Node
static var top_id: int = 0 ## The id of the BotNode at the top of the list

var node_index: int
var id: int = -1:
	set = _set_id

#region Onready Variables

@onready var id_label: RichLabel = %IdLabel
@onready var status_label: RichLabel = %StatusLabel
@onready var duration_label: RichLabel = %DurationLabel

#endregion

#region Ready

func _ready() -> void:
	node_index = get_index()

#endregion

#region Setters

func _set_id(new_id: int) -> void:
	if id == new_id:
		return
	if id > -1:
		clear()

	id = new_id

	setup()

#endregion

#region Control

func setup() -> void:
	id_label.text = "Bot [b]%s[/b]" % (id + 1)
	update_status()
	update_duration(0.0)
	bots.get_child(id).status_text_changed.connect(update_status)
	bots.get_child(id).time_left_changed.connect(update_duration)


func update_status() -> void:
	status_label.write(bots.get_child(id).status_text)


func update_duration(time_left: float) -> void:
	const TEXT: String = "%ss"
	duration_label.text = TEXT % str(time_left).pad_decimals(2)


func clear() -> void:
	bots.get_child(id).status_text_changed.disconnect(update_status)
	bots.get_child(id).time_left_changed.disconnect(update_duration)

#endregion
