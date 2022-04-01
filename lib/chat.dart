import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_front/message_database.dart';
import "package:flutter_front/message.dart";
import "package:flutter_front/chatparam.dart";
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'loading.dart';
import 'messageItem.dart';
import 'chatparam.dart';


class Chat extends StatefulWidget {
  const Chat({Key? key, required this.chatParams}) : super(key: key);
  final ChatParams chatParams;

  @override
  State<Chat> createState() => _ChatState(chatParams);
}

class _ChatState extends State<Chat> {
  final MessageDatabaseService messageService = MessageDatabaseService();
  
  _ChatState(this.chatParams);

  final ChatParams chatParams;

  final TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollController = ScrollController();

  int _nbElement = 20;
  static const int PAGINATION_INCREMENT = 20;
  bool isLoading = false;

    @override
  void initState() {
    super.initState();
    listScrollController.addListener(_scrollListener);
  }

  _scrollListener() {
    if (listScrollController.offset >= listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _nbElement += PAGINATION_INCREMENT;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [buildListMessage(), buildInput()],
        ),
        isLoading ? Loading() : Container()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            buildListMessage(),
            buildInput()
          ],
        )
      ],
    );
  }

  Widget buildListMessage(){
    return Flexible(
      child: StreamBuilder<List<Message>>(
        stream: messageService.getMessage(chatParams.getChatGroupId(), _nbElement),
        builder: (BuildContext context, AsyncSnapshot<List<Message>> snapshot) {
          if (snapshot.hasData){
            List<Message> listMessage = snapshot.data?? List.from([]); //si pas de data = liste vide 
            return ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemBuilder: (context, index) => MessageItem(
                message: listMessage[index],
                userId: chatParams.userUid,
                  isLastMessage: isLastMessage(index, listMessage)
              ),
              itemCount: listMessage.length,
              reverse: true,
              controller: listScrollController, //pagination
              );
          }else {
            return Center(child:Loading());
          }
        },
      ),
    );
  }

  bool isLastMessage(int index, List<Message> listMessage){
    if (index == 0) return true;
    if (listMessage[index].idFrom != listMessage[index-1].idFrom) return true; //si pas le meme envoyeur = dernier message 
    return false; 
  }

   Widget buildInput(){
    return Container(
      width: double.infinity,
      height: 50.0, //baisser le chat 
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.black, width: 0.5)),color: Colors.white),
      child: Row(
        children: [
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(
                icon: Icon(Icons.image),
                onPressed: getImage,
                color: Colors.grey,
              ),
            ),
            color: Colors.white,
          ),
          Flexible(
            child: TextField(
              //onSubmitted: (value){
                //onSendMessage(0); //textEdditingController.text,
              //},
              style:
              TextStyle(color: Colors.black, fontSize: 15.0),
              //controller :textEdditingController;
              decoration: InputDecoration.collapsed(hintText: "Votre message ...",
              hintStyle: TextStyle(color: Colors.black)),
          ),
          ),
            Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: getImage,
                color: Colors.grey,
              ),
            ),
            color: Colors.white,
          ),
      ]
      ),
    );
    
  }
  
  Future getImage() async{
    ImagePicker imagePicker = ImagePicker();
     // ignore: deprecated_member_use
    PickedFile? pickedFile = await imagePicker.getImage(source: ImageSource.gallery); //? si finalement il ne veut pas upload img 
    if (pickedFile !=null){
      setState(() {
        isLoading = true;
      });
      uploadFile(pickedFile);
    }
  }
 Future uploadFile(PickedFile file) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString() + ".jpeg";
    try {
      Reference reference = FirebaseStorage.instance.ref().child(fileName);
      final metadata = SettableMetadata(
          contentType: 'image/jpeg', customMetadata: {'picked-file-path': file.path});
      TaskSnapshot snapshot;
      if (kIsWeb) {
        snapshot = await reference.putData(await file.readAsBytes(), metadata);
      } else {
        snapshot = await reference.putFile(File(file.path), metadata);
      }

      String imageUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    } on Exception {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Erreur ! Essayez à nouveau!");
    }
  }
    void onSendMessage(String content, int type) {
    if (content.trim() != '') {
      messageService.onSendMessage(
          chatParams.getChatGroupId(),
          Message(
              idFrom: chatParams.userUid,
              idTo: chatParams.peer.uid,
              timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
              content: content,
              type: type));
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      textEditingController.clear();
    } else {
      Fluttertoast.showToast(
          msg: 'Rien envoyé', backgroundColor: Colors.red, textColor: Colors.white);
    }
  }
}