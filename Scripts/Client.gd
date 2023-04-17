class_name Client
extends Node

signal packet_data(enemy_name, enemy_direction)
signal client_connected

export var websocket_url := "ws://localhost:5015"

var _client = WebSocketClient.new()
var study_id := ""

func _ready():
	_client.connect("connection_closed", self, "_socket_closed")
	_client.connect("connection_error", self, "_socket_closed")
	_client.connect("connection_established", self, "_socket_connected")
	_client.connect("server_close_request", self, "_server_close_request")
	_client.connect("data_received", self, "_on_data")
	
	print("Connecting to server...")
	var err = _client.connect_to_url(websocket_url)
	if err != OK:
		print("unable to connect")
		set_process(false)

func _process(delta):
	if (_client.get_connection_status() == WebSocketClient.CONNECTION_DISCONNECTED):
		return
	_client.poll()

func _exit_tree():
	_client.disconnect_from_host()

func _server_close_request(code = 1000, reason = ""):
	print("Server closed ocnnection: " + String(code) + ", \"" + reason + "\"")
	_socket_closed(true)

func _socket_closed(was_clean = true):
	print("Closed, clean: ", was_clean)
	set_process(false)
	
func _socket_connected(proto = ""):
	print("Connected with protocol: ", proto)
	emit_signal("client_connected")

func _on_data():
	var data = _client.get_peer(1).get_packet().get_string_from_utf8()
	if (data.length() > 0):
		var updated = data.split("|")
		emit_signal("packet_data", updated[0], updated[1])

func _send_packet(units: Array, chosen_unit: int, direction: String, strategy_select_mode: int):
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
	var packet := "{study_id}|{board}|{chosen_unit}|{direction}|{selection_mode}".format({ 
		"study_id": self.study_id,
		"board": board,
		"chosen_unit": chosen_unit, 
		"direction": direction,
		"selection_mode": strategy_select_mode
	})
	_client.get_peer(1).put_packet(packet.to_utf8())
