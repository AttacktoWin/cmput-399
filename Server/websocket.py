import random
import signal
import sys

from simple_websocket_server import WebSocketServer, WebSocket
from src.Stats import Stats
from src.State import State
from src.Unit import Unit
from src.Environment import EnemyTurn


class RPSWebSocket(WebSocket):
    def handle(self):
        splits = self.data.decode().split('|')
        if len(splits) != 5:
            return

        units = splits[0].split(';')
        player_points = int(splits[1])
        enemy_points = int(splits[2])
        chosen_unit = int(splits[3])
        direction = splits[4]

        parsed = []
        for unit in units:
            # name/hp/x/y/weapon/allegiance
            unit = unit.split('/')
            # TODO: add representation to the packet if it ever gets used
            current_unit = Unit(unit[0], "", Stats(int(unit[1]), int(unit[2]), int(unit[3]), int(unit[4]), int(unit[5])))
            parsed.append(current_unit)

        state = State(parsed)
        state.addPoint(0, player_points)
        state.addPoint(1, enemy_points)
        if len(state.units) > chosen_unit:
            state.units[chosen_unit].move(direction)

        # TODO: just use select_action from Testing.py
        enemy_index = random.randint(0, len(state.enemies) - 1)
        enemy_direction = random.choice(['w', 'a', 's', 'd'])
        state.enemies[enemy_index].move(enemy_direction)
        state.resolve()

        # TODO: send back the moved units
        # [name/hp/x/y/alive]|[name/hp/x/y/alive]
        player_unit = state.units[chosen_unit]
        enemy_unit = state.enemies[enemy_index]
        self.send_message("%s/%i/%i/%i/%i|%s/%i/%i/%i/%i" % (
            player_unit.name,
            player_unit.stats.hp,
            player_unit.stats.x,
            player_unit.stats.y,
            int(player_unit.alive),
            enemy_unit.name,
            enemy_unit.stats.hp,
            enemy_unit.stats.x,
            enemy_unit.stats.y,
            int(enemy_unit.alive)
        ))

    def connected(self):
        print(self.address, "connected")

    def handle_closed(self):
        print(self.address, "closed")


server = WebSocketServer('', 5015, RPSWebSocket)


def close_sig_handler(signal, frame):
    server.close()
    sys.exit()


signal.signal(signal.SIGINT, close_sig_handler)
server.serve_forever()
