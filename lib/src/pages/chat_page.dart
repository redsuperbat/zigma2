import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zigma2/src/DataProvider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../chat.dart';

class ZigmaChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) => buildChatMenu(context);

  Widget buildChatMenu(context) {
    ChatList chatList = DataProvider.of(context).user.user.chatList;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomPadding: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.0),
        child: AppBar(
          elevation: 1.0,
          backgroundColor: Color(0xFFAEDBD3),
          title: Text('Dina aktiva chattar',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF373F51),
                  fontSize: 20)),
          centerTitle: true,
          leading: Container(
            child: IconButton(
              color: Color(0xFFFFFFFF),
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_back),
            ),
          ),
        ),
      ),
      endDrawer: Icon(Icons.settings),
      body: Container(
        child: chatList.chatList.length == 0
            ? Container(
                child: Text('you aint got no chats \n you sad motherfucker'))
            : ListView.builder(
                itemBuilder: (context, index) =>
                    chatCardBuilder(chatList.chatList[index], context),
                itemCount: chatList.chatList.length,
              ),
      ),
    );
  }

  Widget chatCardBuilder(thisChat, context) {
    return GestureDetector(
      onTap: () => DataProvider.of(context).routing.routeSpecificChat(
          context, thisChat, DataProvider.of(context).user.user.token),
      child: Card(
        color: Colors.white,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Row(children: <Widget>[
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: EdgeInsets.only(right: 8),
                  height: 60,
                  width: 60,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: thisChat.chattingUser.profilePic == null
                        ? Image.asset('images/profile_pic2.png')
                        : Image.network(DataProvider.of(context)
                            .user
                            .picUrl(thisChat.chattingUser.id)),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 6,
              child: Column(
                children: <Widget>[
                  Text(
                    thisChat.chattingUser.username,
                    style: TextStyle(fontSize: 30),
                  ),
                  thisChat.chatMessages.length == 0
                      ? Text('')
                      : Text(thisChat.chatMessages[0].text,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black, fontSize: 20)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Icon(Icons.remove, color: Colors.red),
            ),
          ]),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Chat thisChat;
  final String token;

  ChatScreen({this.thisChat, this.token});

  @override
  State createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  WebSocketChannel channel;
  TextEditingController _textController;
  bool _isComposing = false;
  final List<ChatMessage> chatMessages = [];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    initSocket();
  }

  void initSocket() {
   // final List<Message> rawMessages = [];
    channel = IOWebSocketChannel.connect(
        'wss://c2abc9f7.ngrok.io/ws/chat/' +
            widget.thisChat.chattingUser.username +
            '/',
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": "Token " + widget.token
        });
    print('socket to ' +
        widget.thisChat.chattingUser.username +
        ' has been opened');
    MessageHistory messageHistory = MessageHistory('get_history');
    channel.sink.add(json.encode(messageHistory));
    print("I sunk MessageHistory");
    channel.stream.listen((data) {
      if (json.decode(data).toString().contains("data")) {
        MessageHistory messageHistory =
            MessageHistory.fromJson(json.decode(data));
        for (Map<String, dynamic> actuallyMessages
            in messageHistory.fullMessageHistory) {
          print(actuallyMessages["message"]);
          Message thisIsAMessage = Message(text: actuallyMessages["message"]);
          thisIsAMessage.username = actuallyMessages["sender"];
          thisIsAMessage.senderId = actuallyMessages["sender_id"];
          ChatMessage chatMessage = ChatMessage(
              username: thisIsAMessage.username,
              text: thisIsAMessage.text,
              animationController: AnimationController(
                duration: Duration(milliseconds: 500),
                vsync: this,
              ),
              profilePic: thisIsAMessage.username == DataProvider.of(context).user.user.username ?
              null : Image.network(DataProvider.of(context)
                  .user
                  .picUrl(widget.thisChat.chattingUser.id)));
          setState(() => chatMessages.add(chatMessage));
          chatMessage.animationController.forward();
        }
      } else {
        Message messageText = Message.fromJson(json.decode(data));
        print(messageText.username);
        print(messageText.text);
        ChatMessage message = ChatMessage(
          text: messageText.text,
          username: messageText.username,
          animationController: AnimationController(
            duration: Duration(milliseconds: 500),
            vsync: this,
          ),
          profilePic: messageText.username == DataProvider.of(context).user.user.username ?
          null : Image.network(DataProvider.of(context)
              .user
              .picUrl(widget.thisChat.chattingUser.id))
        );
        setState(() => chatMessages.insert(0, message));
        message.animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    for (ChatMessage message in chatMessages)
      message.animationController.dispose();
    super.dispose();
  }

  void sendData() {
    Message newMessage;
    if (_textController.text.isNotEmpty) {
      newMessage = Message(
        text: _textController.text,
      );
      channel.sink.add(json.encode(newMessage));
      print('message sink');
      _textController.clear();
      _isComposing = !_isComposing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomPadding: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: AppBar(
            iconTheme: IconThemeData(color: Colors.transparent),
            elevation: 0.0,
            backgroundColor: Color(0xFFAEDBD3),
            title:
                Text('Du chattar med ' + widget.thisChat.chattingUser.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    )),
            centerTitle: true,
            leading: Container(
              child: IconButton(
                color: Color(0xFFFFFFFF),
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back),
              ),
            ),
            actions: <Widget>[],
          ),
        ),
        body: Container(
            child: Column(
              children: <Widget>[
                Flexible(
                  child: ListView.builder(
                    padding: EdgeInsets.all(8.0),
                    reverse: true,
                    itemBuilder: (_, int index) => chatMessages[index],
                    itemCount: chatMessages.length,
                  ),
                ),
                Divider(height: 1.0),
                Container(
                  decoration: BoxDecoration(color: Colors.white),
                  child: _buildTextComposer(),
                ),
              ],
            ),
            decoration: BoxDecoration(
                border: Border(
              top: BorderSide(color: Colors.grey[200]),
            ))));
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Color(0xFFECA72C)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                decoration:
                    InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                child: IconButton(
                  icon: Icon(Icons.send),
                  color: _isComposing ? Color(0xFFAEDBD3) : Colors.grey,
                  onPressed: _isComposing ? () => sendData() : null,
                )),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage(
      {this.text, this.username, this.animationController, this.profilePic});

  final Image profilePic;
  final String text;
  final String username;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    bool myChat = username == DataProvider.of(context).user.user.username;
    return SizeTransition(
      sizeFactor:
          CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      axisAlignment: 0.0,
      child: Container(
        child: Row(
          mainAxisAlignment:
              myChat ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            myChat ? Padding(padding: const EdgeInsets.all(30.0)) : Container(),
            Flexible(
              child: Card(
                  color: myChat ? Color(0xFF373F51) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: RichText(
                      softWrap: true,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                          text: text,
                          style: TextStyle(
                              color:
                                  myChat ? Colors.white : Color(0xFF373F51))),
                    ),
                  )),
            ),
            myChat ? Container() : Padding(padding: const EdgeInsets.all(20.0)),
            myChat
                ? Container()
                : ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 50,
                      height: 50,
                      child: FittedBox(fit: BoxFit.fitWidth, child: profilePic),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class Message {
  Message({this.text});

  String username;
  String text;
  String receivingUser;
  int senderId;
  int receiverId;

  Map<String, dynamic> toJson() => {
        'message': text,
      };

  Message.fromJson(Map map)
      : text = map['message'],
        username = map['sender'],
        receivingUser = map['receiver'],
        senderId = map['sender_id'],
        receiverId = map['receiver_id'];
}

class MessageHistory {
  List fullMessageHistory;
  String command;

  MessageHistory(this.command);

  Map<String, dynamic> toJson() => {
        'command': command,
      };

  MessageHistory.fromJson(Map map) : fullMessageHistory = map['data'];
}
