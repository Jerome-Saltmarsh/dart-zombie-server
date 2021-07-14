import 'dart:convert';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';

const commandMoveUp = 0;
const commandMoveRight = 1;
const commandMoveDown = 2;
const commandMoveLeft = 3;
const commandSpawn = 4;
const commandUpdate = 5;
const commandId = 6;


void main() {
  print('starting web socket server');

  List<dynamic> characters = [];
  int _id = 0;

  dynamic findCharacterById(int id){
    return characters.firstWhere((element) => element['id'] == id);
  }

  int spawnCharacter(){
    Map<String, dynamic> object = new Map();
    object['x'] = 500;
    object['y'] = 400;
    object['id'] = _id;
    characters.add(object);
    _id++;
    return object['id'];
  }

  var handler = webSocketHandler((webSocket) {
    webSocket.stream.listen((message) {

      Map<String, dynamic> response = Map();
      response['command'] = commandUpdate;
      response['value'] = characters;
      webSocket.sink.add(jsonEncode(response));

      if(message == commandUpdate) return;

      dynamic request = jsonDecode(message);
      dynamic command = request['command'];
      dynamic id = request['id'];

      if (command == commandSpawn) {
        var id = spawnCharacter();
        Map<String, dynamic> response = Map();
        response['command'] = commandId;
        response['value'] = id;
        webSocket.sink.add(jsonEncode(response));
      }
      if (command == commandMoveUp){
        dynamic character = findCharacterById(id);
        character['y'] -= 10;
      }
      if (command == commandMoveRight){
        dynamic character = findCharacterById(id);
        character['x'] += 10;
      }
      if (command == commandMoveDown){
        dynamic character = findCharacterById(id);
        character['y'] += 10;
      }
      if (command == commandMoveLeft){
        dynamic character = findCharacterById(id);
        character['x'] -= 10;
      }
    });
  });


  shelf_io.serve(handler, '0.0.0.0', 8080).then((server) {
    print('Serving at ws://${server.address.host}:${server.port}');
  });
}

