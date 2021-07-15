import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

import 'common.dart';

void main() {
  print('starting web socket server');

  List<dynamic> _characters = [];

  void fixedUpdate() {
    _characters.forEach(updateCharacter);
  }

  const host = '0.0.0.0';
  const port = 8080;
  Timer updateTimer =
      Timer.periodic(Duration(milliseconds: 1000 ~/ 60), (timer) {
    fixedUpdate();
  });
  int _id = 0;

  dynamic findCharacterById(int id) {
    return _characters.firstWhere((element) => element[keyPlayerId] == id,
        orElse: () {
      throw Exception("character not found with id $id");
    });
  }

  int spawnCharacter() {
    Map<String, dynamic> object = new Map();
    object[keyPositionX] = 500;
    object[keyPositionY] = 400;
    object[keyPlayerId] = _id;
    object[keyDirection] = directionDown;
    object[keyState] = characterStateIdle;
    _characters.add(object);
    _id++;
    return _id - 1;
  }

  var handler = webSocketHandler((webSocket) {
    webSocket.stream.listen((message) {
      dynamic messageObject = jsonDecode(message);
      dynamic command = messageObject[keyCommand];

      switch (command) {
        case commandSpawn:
          var id = spawnCharacter();
          Map<String, dynamic> response = Map();
          response[keyCommand] = commandSpawn;
          response[keyValue] = id;
          webSocket.sink.add(jsonEncode(response));
          return;
        case commandUpdate:
          Map<String, dynamic> response = Map();
          if (messageObject[keyPlayerX] != null) {
            dynamic playerCharacter = findCharacterById(messageObject[keyPlayerId]);
            playerCharacter[keyPositionX] = playerCharacter[keyPositionX];
            playerCharacter[keyPositionY] = playerCharacter[keyPositionY];
            playerCharacter[keyDirection] = playerCharacter[keyDirection];
            playerCharacter[keyState] = playerCharacter[keyState];
          }
          response[keyCommand] = commandUpdate;
          response[keyValue] = _characters;
          webSocket.sink.add(jsonEncode(response));
          return;
        case commandPlayer:
          dynamic playerId = messageObject[keyPlayerId];
          dynamic playerCharacter = findCharacterById(playerId);
          int direction = messageObject[keyPlayerDirection];
          int characterState = messageObject[keyState];
          playerCharacter[keyState] = characterState;
          playerCharacter[keyDirection] = direction;
      }
    });
  });

  shelf_io.serve(handler, host, port).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}
