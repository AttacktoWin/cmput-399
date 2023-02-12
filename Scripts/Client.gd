class_name Client
extends Node

signal packet_data(enemy_unit, player_unit)
signal client_connected

export var websocket_url := "ws://localhost:5015"

var _client = WebSocketClient.new()
var study_id := ""

func _ready():
	_client.connect("connection_closed", self, "_socket_closed")
	_client.connect("connection_error", self, "_socket_closed")
	_client.connect("connection_established", self, "_socket_connected")
	_client.connect("data_received", self, "_on_data")
	
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print("unable to connect")
		set_process(false)

func _process(delta):
	_client.poll()

func _socket_closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)
	
func _socket_connected(proto = ""):
	print("Connected with protocol: ", proto)
	emit_signal("client_connected")

func _on_data():
	var data = _client.get_peer(1).get_packet().get_string_from_utf8()
	if (data.length() > 0):
		var changed_units := data.split("|") as PoolStringArray
		var player_unit = changed_units[0].split("/")
		var enemy_unit = changed_units[1].split("/")
		emit_signal("packet_data", enemy_unit, player_unit)

func _send_packet(units: Array, player_points: int, enemy_points: int, chosen_unit: int, direction: String):
	var board := ""
	for i in range(len(units)):
		board += "{name}/{hp}/{x}/{y}/{weapon}/{allegiance}".format({
			"name": units[i].unit_name,
			"hp": units[i].hp,
			"x": units[i].x,
			"y": units[i].y,
			"weapon": units[i].weapon,
			"allegiance": units[i].allegiance
		})
		if (i < len(units) - 1):
			board += ";"
	var packet := "{study_id}|{board}|{player_points}|{enemy_points}|{chosen_unit}|{direction}".format({ 
		"study_id": self.study_id,
		"board": board, 
		"player_points": player_points,
		"enemy_points": enemy_points,
		"chosen_unit": chosen_unit, 
		"direction": direction
	})
	_client.get_peer(1).put_packet(packet.to_utf8())
