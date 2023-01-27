import socket
from src import State, Stats, Unit
from src.Environment import EnemyTurn


TCP_IP = '127.0.0.1'
TCP_PORT = 5015
BUFFER_SIZE = 20400

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.bind(TCP_IP, TCP_PORT)
s.listen(1)

conn, address = s.accept()

while 1:
    try:
        data = conn.recv(BUFFER_SIZE)

        if len(data) > 0:
            print("Data: " + str(data) + ", " + str(len(data)))

            # units|player_points|enemy_points|chosen_unit|direction
            splits = data.split('|')
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
                current_unit = Unit(unit[0], "", Stats(unit[1], unit[2], unit[3], unit[4], unit[5]))
                parsed.append(current_unit)

            state = State(*parsed)
            state.addPoint(0, player_points)
            state.addPoint(1, enemy_points)

            # TODO: just use select_action from Testing.py
            EnemyTurn(state.enemies, state.players)

            # TODO: send back the moved units
            # [name/hp/x/y/alive]|[name/hp/x/y/alive]

            conn, addr = s.accept()
    except KeyboardInterrupt:
        conn.close()
        del conn
        break
