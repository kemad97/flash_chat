
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _fireStore = FirebaseFirestore.instance;
final _auth = FirebaseAuth.instance;




User? getCurrentUser(){
  return _auth.currentUser;
}


class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  const ChatScreen({super.key});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose(); // Dispose controller
    super.dispose();
  }

  void sendMessage(){
    final user = getCurrentUser();
    final text = _messageController.text.trim();

    if (user != null && text.isNotEmpty) {
      _fireStore.collection('messages').add({
        'text': text,
        'email': user.email,
        'timestamp': FieldValue.serverTimestamp(), // Add this line

      });
      _messageController.clear();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              //Implement logout functionality
              _auth.signOut();
              Navigator.pop(context); // go back to previous screen (e.g., login)
            },
          ),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: MessageStream(scrollController: _scrollController),
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  MaterialButton(
                    onPressed: sendMessage,
                    child: Text('Send', style: kSendButtonTextStyle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  final ScrollController scrollController;

  MessageStream({ required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _fireStore.collection('messages')
          .orderBy('timestamp', descending: false) // Add this line
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final messages = snapshot.data!.docs;
        List<MessageBubbleWidget> messageBubbles = [];
        for (var message in messages) {
          final messageText = message['text'] ?? '';
          final sender = message['email'] ?? '';
          final user = getCurrentUser();
          final isMe = user != null && sender == user.email;

          messageBubbles.add(MessageBubbleWidget(sender: sender,
              msgText: messageText , isMe: isMe,));

        }


        // Scroll to bottom after rebuild
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView(
          //reverse: true,
          controller: scrollController, // <<< attach the controller

          children: messageBubbles,
          padding: EdgeInsets.symmetric(horizontal: 10.0 , vertical: 12.0),
        );
      },
    );
  }
}

class MessageBubbleWidget extends StatelessWidget {
  final String sender;
  final String msgText;
  final bool isMe;

  MessageBubbleWidget({
    required this.sender,
    required this.msgText,
    this.isMe = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(fontSize: 10.0, color: Colors.grey),
          ),
          Material(
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.0),
              topRight: Radius.circular(30.0),
              bottomLeft: isMe ? Radius.circular(30.0) : Radius.circular(0),
              bottomRight: isMe ? Radius.circular(0) : Radius.circular(30.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                msgText,
                style: TextStyle(
                  fontSize: 20.0,
                  color: isMe ? Colors.white : Colors.black54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}