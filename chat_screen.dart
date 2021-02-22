import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'package:stalkerclone/main.dart';

import 'package:stalkerclone/screens/chat.dart';
import 'package:stalkerclone/screens/conts.dart';
import 'package:stalkerclone/screens/custom_icons_icons.dart';
import 'package:stalkerclone/screens/home_screen.dart';

import 'package:stalkerclone/screens/search_screen.dart';

class ChatScreen extends StatefulWidget {
  final String currentUserId;

  ChatScreen({Key key, @required this.currentUserId}) : super(key: key);

  @override
  _ChatScreenState createState() =>
      _ChatScreenState(currentUserId: currentUserId);
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  AnimationController _anicontroller, _scaleController;
  AnimationController _footerController;
  RefreshController _refreshController = RefreshController();
  bool keepAlive = false;
  _ChatScreenState({Key key, @required this.currentUserId});

  final String currentUserId;
  final FirebaseMessaging firebaseMessaging = new FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoading = false;

  final int def = 0;
  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
  String groupChatId = '';

  @override
  void initState() {
    _anicontroller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 2000));
    _scaleController =
        AnimationController(value: 0.0, vsync: this, upperBound: 1.0);
    _footerController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 2000));
    _refreshController.headerMode.addListener(() {
      if (_refreshController.headerStatus == RefreshStatus.idle) {
        _scaleController.value = 0.0;
        _anicontroller.reset();
      } else if (_refreshController.headerStatus == RefreshStatus.refreshing) {
        _anicontroller.repeat();
      }
    });
    super.initState();
    registerNotification();
    configLocalNotification();
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();

    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      showNotification(message['notification']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) {
      // print('token: $token');
      Firestore.instance
          .collection('users')
          .document(currentUserId)
          .updateData({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('launch_background');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // void onItemMenuPress(Choice choice) {
  //   if (choice.title == 'Log out') {
  //     handleSignOut();
  //   } else {
  //     Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
  //   }
  // }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      'channel Id',
      'Flutter chat',
      'your channel description',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));
  }

  onBackPress() {
    return Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _refreshController.dispose();
    _scaleController.dispose();
    _footerController.dispose();
    _anicontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff171717),
      appBar: AppBar(
        backgroundColor: Color(0xff222222),
        centerTitle: true,
        title: Text('Messaging',
            style: TextStyle(
              //  color:Color(0xffd1001d),
              color: Colors.white,
              fontFamily: 'Tahu',
              fontSize: 25,
            )),
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <
          Widget>[
        // List
        Expanded(
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                // child: Container(
                //   child: StreamBuilder(
                //     stream: Firestore.instance.collection('users').snapshots(),
                //     builder: (context, snapshot) {
                //       if (!snapshot.hasData) {
                //         return Center(
                //           child: CircularProgressIndicator(
                //             valueColor:
                //                 AlwaysStoppedAnimation<Color>(themeColor),
                //           ),
                //         );
                //       } else {
                //         return ListView.builder(
                //             padding: EdgeInsets.all(10.0),
                //             itemCount: snapshot.data.documents.length,
                //             shrinkWrap: true,
                //             itemBuilder: (context, index) =>
                //                 AnimationConfiguration.staggeredList(
                //                     position: index,
                //                     duration: const Duration(milliseconds: 375),
                //                     child: SlideAnimation(
                //                         verticalOffset: 50.0,
                //                         child: FadeInAnimation(
                //                             child: buildItem(
                //                                 context,
                //                                 snapshot
                //                                     .data.documents[index])))));
                //       }
                //     },
                //   ),
                // ),
                child: Container(
                  child: StreamBuilder(
                      stream: Firestore.instance
                          .collection('messages')
                          .where('users.' + widget.currentUserId,
                              isEqualTo: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(themeColor),
                            ),
                          );
                        } else {
                          return SmartRefresher(
                              enablePullUp: true,
                              controller: _refreshController,
                              onRefresh: () async {
                                await Future.delayed(
                                    Duration(milliseconds: 1000));
                                _refreshController.refreshCompleted();
                              },
                              onLoading: () async {
                                await Future.delayed(
                                    Duration(milliseconds: 1000));

                                setState(() {});
                                _refreshController.loadComplete();
                              },
                              child: ListView.builder(
                                  padding: EdgeInsets.all(4.0),
                                  itemCount: snapshot.data.documents == null
                                      ? 1
                                      : snapshot.data.documents.length + 1,
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      // return the header
                                      return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                            bottom: 16.0,
                                          ),
                                          child: FlatButton(
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          SearchScreen(
                                                              redirect:
                                                                  'message')));
                                            },
                                            child: Container(
                                              // height: 40,
                                              decoration: BoxDecoration(
                                                color: Color(0xff171717),
                                                border: Border.all(
                                                  color: Color(0xff313131),
                                                  width: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Row(
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.search,
                                                      size: 30.0,
                                                      color: Colors.white38,
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8.0),
                                                      child: Text(
                                                        "Search",
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            color: Colors.grey),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ));
                                    }
                                    index -= 1;

                                    return AnimationConfiguration.staggeredList(
                                        position: index,
                                        duration:
                                            const Duration(milliseconds: 100),
                                        child: SlideAnimation(
                                            verticalOffset: 50.0,
                                            child: FadeInAnimation(
                                                child: buildItem(
                                                    context,
                                                    snapshot.data
                                                        .documents[index]))));
                                  }),
                              footer: CustomFooter(
                                onModeChange: (mode) {
                                  if (mode == LoadStatus.loading) {
                                    _scaleController.value = 0.0;
                                    _footerController.repeat();
                                  }
                                  // else if (_posts.length <= count) {
                                  //   mode = LoadStatus.noMore;
                                  // }
                                  else {
                                    _footerController.reset();
                                  }
                                },
                                builder: (context, mode) {
                                  Widget child;
                                  switch (mode) {
                                    case LoadStatus.failed:
                                      child = Text("failed,click retry");
                                      break;
                                    case LoadStatus.noMore:
                                      child = Text("no more data");
                                      break;
                                    default:
                                      child = SpinKitFadingCircle(
                                        size: 30.0,
                                        controller: _footerController,
                                        itemBuilder: (_, int index) {
                                          return DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      );
                                      break;
                                  }
                                  return Container(
                                    height: 60,
                                    child: Center(
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                              header: CustomHeader(
                                refreshStyle: RefreshStyle.Behind,
                                onOffsetChange: (offset) {
                                  if (_refreshController.headerMode.value !=
                                      RefreshStatus.refreshing)
                                    _scaleController.value = offset / 80.0;
                                },
                                builder: (c, m) {
                                  return Container(
                                    child: FadeTransition(
                                      opacity: _scaleController,
                                      child: ScaleTransition(
                                        child: SpinKitFadingCircle(
                                          size: 30.0,
                                          controller: _anicontroller,
                                          itemBuilder: (_, int index) {
                                            return DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                        ),
                                        scale: _scaleController,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                  );
                                },
                              ));
                        }
                      }),
                ),
              ),
            ],
          ),

          // Loading
          // Positioned(
          //   child: isLoading
          //       ? Container(
          //           child: Center(
          //             child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
          //           ),
          //           color: Colors.white.withOpacity(0.8),
          //         )
          //       : Container(),
          // )
        )
      ]),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    getLastMessage(String userId, String peerId) {
      String groupChatId = '';
      String lastmessage;
      // print("entering getlastmessage");
      if (userId.hashCode <= peerId.hashCode) {
        groupChatId = '$userId-$peerId';
      } else {
        groupChatId = '$peerId-$userId';
      }

      return new StreamBuilder(
          stream: Firestore.instance
              .collection('messages')
              .document(groupChatId)
              .collection(groupChatId)
              .limit(1)
              .snapshots(),
          builder: (BuildContext context, snapshot) {
            print(snapshot);
            if (snapshot.hasError) return Text('${snapshot.error}');
            if (snapshot.hasData) return Text('${snapshot.data}');
            if (!snapshot.hasData) {
              return new Text('Loading...');
            } else {
              final List<DocumentSnapshot> documentsData =
                  snapshot.data.documents;
              // print(documentsData.toString());
              print(documentsData[0]);
              if (documentsData[0]['type'] == 1) {
                lastmessage = 'Image message';
                return new Text('123');
              } else {
                lastmessage = documentsData[0]['content'];
                return new Text('1234');
              }
            }
          }).toString();
    }

    if (document['id'] == currentUserId) {
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Stack(
                children: [
                  Material(
                    child: document['photoUrl'] != ''
                        ? CachedNetworkImage(
                            placeholder: (context, url) => Container(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.0,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(themeColor),
                              ),
                              width: 50.0,
                              height: 50.0,
                              // padding: EdgeInsets.all(15.0),
                            ),
                            imageUrl: document['photoUrl'],
                            width: 50.0,
                            height: 50.0,
                            fit: BoxFit.cover,
                          )
                        : Icon(
                            Icons.account_circle,
                            size: 50.0,
                            color: greyColor,
                          ),
                    borderRadius: BorderRadius.all(Radius.circular(25.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  document['isActive']
                      ? Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 15,
                            width: 15,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6.0, top: 12.0),
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          document['name'],
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w400),
                        ),
                        Text(
                          getLastMessage(
                                  widget.currentUserId, document.documentID)
                              .toString(),
                          style: TextStyle(color: Color(0xFF424f72)),
                        )
                      ],
                    ),
                    margin: EdgeInsets.only(left: 5.0),
                  ),
                ),
              ),
              // Padding(
              //   padding: EdgeInsets.only(left: 33, top: 8),
              //   child: Container(
              //     height: 14,
              //     width: 14,
              //     child: Center(
              //       child: Text(
              //         '2',
              //         style: TextStyle(color: Colors.white, fontSize: 12),
              //       ),
              //     ),
              //     decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         gradient: LinearGradient(
              //             colors: [Color(0xFFfacbab), Color(0xFFf1869d)],
              //             begin: const FractionalOffset(0.0, 0.0),
              //             end: const FractionalOffset(0.5, 0.0),
              //             stops: [0.0, 1.0],
              //             tileMode: TileMode.clamp)),
              //   ),
              // )
            ],
          ),

          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Chat(
                          currentUserId: widget.currentUserId,
                          peerId: document.documentID,
                          peerAvatar: document['photoUrl'],
                          peerName: document['name'],
                          peerActive: document['isActive'],
                        )));
            onSeenMessage(currentUserId, document.documentID);
          },
          // color: greyColor2,
          // padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(
          bottom: 20.0,
        ),
      );
    }
  }

  void onSeenMessage(String userId, String peerId) async {
    String groupChatId = '';

    if (userId.hashCode <= peerId.hashCode) {
      groupChatId = '$userId-$peerId';
    } else {
      groupChatId = '$peerId-$userId';
    }
    CollectionReference ref = Firestore.instance
        .collection('messages')
        .document(groupChatId)
        .collection(groupChatId);

    QuerySnapshot eventsQuery = await ref
        .where('idTo', isEqualTo: currentUserId)
        .where('isSeen', isEqualTo: 0)
        .getDocuments();

    eventsQuery.documents.forEach((msgDoc) {
      msgDoc.reference.updateData({'isSeen': 1});
    });
  }
}

// class Choice {
//   const Choice({this.title, this.icon});

//   final String title;
//   final IconData icon;
// }
