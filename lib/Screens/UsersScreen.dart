import 'package:flashchat/Screens/chat_screen.dart';
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

class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
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
        title: Text('⚡Metanoia Admin'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.power_settings_new),
            onPressed: () {
              setState(() {
                Alert(
                  context: context,
                  type: AlertType.warning,
                  title: "Logout ALERT",
                  desc: "Do you want to Logout",
                  buttons: [
                    DialogButton(
                      child: Text(
                        "Yes",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () {
                        setState(() {
                          _auth.signOut();
                          Navigator.pushNamed(context, 'welcome_screen');
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
                  print("getting xd ${snapshot.data.email}");
                  return UsersStream(
                    userId: snapshot.data.email,
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
            
          ],
        ),
      ),
    );
  }
}

class UsersStream extends StatelessWidget {
  final String userId;
  UsersStream({@required this.userId});

  @override
  Widget build(BuildContext context) {
    print("lololol $userId");
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection("users").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        else if(snapshot.data.documents.length == 0){
          print("NO DATA");
          return Center(
            child: Text("No Data")
          );
        }
        final users = snapshot.data.documents;
        print("xxdd $users");
        List<UserBubble> emailBubbles = [];
        for (var user in users) {
          final email = user.data['email'];
          final answered = user.data['answered'];


          final userBubble = UserBubble(
            email: email,
            answered: answered,
            uid: userId,
          );

          emailBubbles.add(userBubble);
        }
        return Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: emailBubbles,
          ),
        );
      },
    );
  }
}

class UserBubble extends StatelessWidget {
  final String email;
  final String uid;
  final String answered;
  UserBubble({this.email, this.answered, this.uid, });

  String splitMailAddress(String mailID) {
    var name = mailID.split('@');
    return name[0];
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius:  BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
              bottomRight: Radius.circular(30),
              bottomLeft: Radius.circular(30)),
      elevation: 10,
      color: answered != loginUser.email ? Colors.grey :  color,
      child: InkWell(
        borderRadius:  BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
            bottomLeft: Radius.circular(30)),
        onTap: () async {
          if( answered == 'no' || answered == loginUser.email){
            print("kkk");

            QuerySnapshot snapshots = await _firestore.collection("users").getDocuments();
            String docId = "";
            for(DocumentSnapshot snap in snapshots.documents){
              if(snap.data['email'] == email){
                docId = snap.documentID;
              }
            }
            await _firestore.collection("users").document(docId).updateData({"answered": loginUser.email});
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatScreen(email: email, uid: uid,)
              ),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 75, vertical: 15),
          child: Text((answered == "no") || answered == loginUser.email? '$email': '$email, Answered by $answered',textAlign: TextAlign.center,),
        ),
      ),
    );
  }
}
