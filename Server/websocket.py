import os
import signal
import pickle
import sys

from simple_websocket_server import WebSocketServer, WebSocket
from src.Stats import Stats
from src.State import State
from src.Unit import Unit
from src.Learning import select_action, get_move_set
from src.adapter import adapter

QList = []
QNames = []
for f in os.listdir('src/files'):
    if f.endswith('.pkl'):
        QList.append(pickle.load(open('src/files/%s' % f, 'rb')))
        QNames.append(f[:-4])


class RPSWebSocket(WebSocket):
    adapters = {}

    def handle(self):
        # id|board|chosen_unit|direction|select_mode
        splits = self.data.decode().split('|')
        if len(splits) != 5:
            return

        study_id = splits[0]
        units = splits[1].split(';')
        chosen_unit = int(splits[2])
        direction = splits[3]
        select_mode = int(splits[4])

        parsed = []
        for unit in units:
            # name/hp/x/y/weapon/allegiance
            unit = unit.split('/')
            current_unit = Unit(unit[0], "",
                                Stats(int(unit[1]), int(unit[2]), int(unit[3]), int(unit[4]), int(unit[5])))
            parsed.append(current_unit)

        state = State(parsed)

        if study_id == 'tutorial':
            if len(state.players) > chosen_unit:
                state.players[chosen_unit].move(direction)
            Q = QList[0]
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
            return

        if not os.path.exists('logs/%s.txt' % study_id):
            with open('logs/%s.txt' % study_id, 'w') as log_file:
                log_file.write("Player Unit, Player Direction, Player Strategy, Chosen Strategy, "
                               "Enemy Unit, Enemy Move\n")

        with open('logs/%s.txt' % study_id, 'a') as log_file:
            closest_strategy = 0
            if study_id not in self.adapters.keys():
                self.adapters[study_id] = adapter()
            else:
                closest_strategy = self.adapters[study_id].getStrategy()
            Q = self.adapters[study_id].Q2[closest_strategy]
            Q, move_list = get_move_set(Q, state, state.players, state.enemies)
            index = move_list.index([chosen_unit, direction])
            self.adapters[study_id].addMove(state.hash(0), index, len(move_list))
            if len(state.players) > chosen_unit:
                state.players[chosen_unit].move(direction)

            # TODO: select a control group based on select_mode
            counter_index = (closest_strategy + 1) % len(self.adapters[study_id].Q2)
            counter = self.adapters[study_id].Q2[counter_index]
            counter, action_list, action = select_action(counter, state, state.enemies, state.players)
            enemy_index = action_list[0]
            enemy_direction = action_list[1]
            state.enemies[enemy_index].move(enemy_direction)
            state.resolve()

            log_file.write("%i,%s,%s,%s,%i,%s\n" % (
                chosen_unit,
                direction,
                QNames[closest_strategy],
                QNames[counter_index],
                enemy_index,
                enemy_direction
            ))

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
