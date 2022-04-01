
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'chat.dart';
import 'chatparam.dart';

class chatScreen extends StatelessWidget {
  final ChatParams chatParams;
  const chatScreen({Key? key, required this.chatParams}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0.0,
        title: Text(
          "#le_nom_de_la_personne", //+chatParams.peer.name //Sinon mettre juste le nom de la personne avec qui elle discute
          style: const TextStyle(color:Colors.white),
      ),
      ),
      body: Chat(chatParams: chatParams),
    );
  }
}