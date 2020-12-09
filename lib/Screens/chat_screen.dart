import 'package:flutter/material.dart';
import 'package:flashchat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:random_color/random_color.dart';

final _firestore = Firestore.instance;
FirebaseUser loginUser;
final _auth = FirebaseAuth.instance;
RandomColor randomColor = RandomColor();
Color color = randomColor.randomColor();

class ChatScreen extends StatefulWidget {
  final String email;
  final String uid;

  const ChatScreen({Key key, @required this.email, @required this.uid}) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final textEditingController = TextEditingController();

  String messagetext = '';
  String userid;

  @override
  void initState() {
    super.initState();
    getcurrentuser();
  }

  void getcurrentuser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loginUser = user;
        userid = user.email;
        print("logging ${loginUser.email}");
      }
      // print(userid);
    } catch (e) {
      print(e);
    }
  }

  // void messagestream() async {
  //   //stream function of data from firestone
  //   await for (var snapshot in _firestore.collection('messages').snapshots()) {
  //     for (var message in snapshot.documents) {
  //       print(message.data);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('⚡Metanoia'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () {
              setState(() {
                Alert(
                  context: context,
                  type: AlertType.warning,
                  title: "end chat ALERT",
                  desc: "Do you want to end the user's chat ?",
                  buttons: [
                    DialogButton(
                      child: Text(
                        "Yes",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () async {
                        QuerySnapshot msgQuery  = await _firestore.collection(widget.email).getDocuments();
                        for (DocumentSnapshot ds in msgQuery.documents){
                          ds.reference.delete();
                        }

                        QuerySnapshot userQuery  = await _firestore.collection("users").getDocuments();
                        for (DocumentSnapshot ds in userQuery.documents){
                          if(ds['email'] == widget.email){
                            ds.reference.delete();
                            break;
                          }
                        }
                        setState(() {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        });
                      },
                      color: Color.fromRGBO(0, 179, 134, 1.0),
                    ),
                    DialogButton(
                      child: Text(
                        "NO",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () {
                        setState(() {
                          Navigator.pushNamed(context, 'chat_page');
                        });
                      },
                      gradient: LinearGradient(colors: [
                        Color.fromRGBO(116, 116, 191, 1.0),
                        Color.fromRGBO(52, 138, 199, 1.0)
                      ]),
                    )
                  ],
                ).show();
              });
            },
          ),
        ],
        backgroundColor: Color(0xFF47535E),
        elevation: 25,
        // backgroundColor: Color(0XFF4dd0e1).withOpacity(0.90),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FutureBuilder<FirebaseUser>(
              future:
              _auth.currentUser(), // a previously-obtained Future<String> or null
              builder: (BuildContext context, AsyncSnapshot<FirebaseUser> snapshot) {
                if (snapshot.hasData) {
                  print("getting xd ${widget.email}");
                  return MessagesStream(
                    userId: widget.email,
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text('Error: ${snapshot.error}'),
                        )
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text('Error: ${snapshot.error}'),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                          controller: textEditingController,
                          onChanged: (value) {
                            setState(() {
                              messagetext = value;
                            });
                          },
                          decoration: kMessageTextFieldDecoration),
                    ),
                    FlatButton(
                      onPressed: () {
                        textEditingController.clear();
                        _firestore.collection('${widget.email}').add({
                          'sender': userid,
                          'text': messagetext,
                          'time': FieldValue.serverTimestamp(),
                        });
                      },
                      child: Icon(
                        Icons.send,
                        color: Color(0XFF4dd0e1),
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 5,
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  final String userId;
  MessagesStream({@required this.userId});

  @override
  Widget build(BuildContext context) {
    print("lololol $userId");
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(userId).orderBy('time').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message.data['text'];
          final messageSender = message.data['sender'];

          final currentUser = loginUser.email;

          final messageBubble = MessageBubble(
            sender: messageSender,
            message: messageText,
            isme: currentUser == messageSender,
          );

          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isme;
  final String sender;
  MessageBubble({this.message, this.sender, this.isme});

  String splitMailAddress(String mailID) {
    var name = mailID.split('@');
    return name[0];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: isme
          ? EdgeInsets.fromLTRB(100, 8, 8, 8)
          : EdgeInsets.fromLTRB(8, 8, 100, 8),
      child: Column(
        crossAxisAlignment:
            isme ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            splitMailAddress(sender),
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(
            height: 4,
          ),
          Material(
            borderRadius: isme
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30))
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30)),
            elevation: 10,
            color: isme ? Color(0XFF4dd0e1).withOpacity(0.90) : color,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text('$message'),
            ),
          ),
        ],
      ),
    );
  }
}
