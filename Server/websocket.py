import os
import signal
import sys
import pickle

from simple_websocket_server import WebSocketServer, WebSocket
from src.Stats import Stats
from src.State import State
from src.Unit import Unit
from src.Learning import select_action
# from src.diffCheck import diffCheck
from src.adapter import adapter


class RPSWebSocket(WebSocket):
    QList = []
    adapters = {}

    def __init__(self):
        super()
        for f in os.listdir('src/files'):
            if f.endswith('.pkl'):
                self.QList.append(pickle.load(open('src/files/%s' % f, 'rb')))
    def handle(self):
        # id|board|player_points|enemy_points|chosen_unit|direction
        splits = self.data.decode().split('|')
        if len(splits) != 6:
            return

        # TODO: Load this using diffCheck
        Q = pickle.load(open('src/files/general1.pkl', 'rb'))
        id = splits[0]
        units = splits[1].split(';')
        player_points = int(splits[2])
        enemy_points = int(splits[3])
        chosen_unit = int(splits[4])
        direction = splits[5]

        parsed = []
        for unit in units:
            # name/hp/x/y/weapon/allegiance
            unit = unit.split('/')
            current_unit = Unit(unit[0], "", Stats(int(unit[1]), int(unit[2]), int(unit[3]), int(unit[4]), int(unit[5])))
            parsed.append(current_unit)

        state = State(parsed)
        state.addPoint(0, player_points)
        state.addPoint(1, enemy_points)
        if id not in self.adapters.keys():
            self.adapters[id] = adapter()
            # TODO: figure out what to do
            self.adapters[id].addMove(state.hash(0), )
        if len(state.units) > chosen_unit:
            state.units[chosen_unit].move(direction)

        Q, action_list, action = select_action(Q, state, state.enemies, state.players)
        enemy_index = action_list[0]
        enemy_direction = action_list[1]
        state.enemies[enemy_index].move(enemy_direction)
        state.resolve()

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
