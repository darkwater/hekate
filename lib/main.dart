import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'host.dart';
import 'hostView/hostView.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Hekate",
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(backgroundColor: Colors.blue),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hekate"),
      ),
      body: Center(
        child: FutureBuilder<List<Host>>(
          future: Future.value([
            Host(
              label: "fubuki",
              host: "172.24.0.1",
              password: "letmein",
            ),
            Host(
              label: "tetsuya",
              host: "172.24.0.2",
              password: "letmein",
            ),
            Host(
              label: "nagumo",
              host: "172.24.0.3",
              password: "letmein",
            ),
            Host(
              label: "sinon",
              host: "172.24.0.6",
              password: "letmein",
            ),
          ]),
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              final hosts = snapshot.data!;
              return ListView.builder(
                itemCount: hosts.length,
                itemBuilder: (context, idx) {
                  return HostListTile(hosts[idx]);
                },
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }

  Future<String?> askFor(String title, BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        final ctrl = TextEditingController();

        return AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            maxLines: 20,
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Submit"),
              onPressed: () {
                Navigator.of(context).pop(ctrl.text);
              },
            )
          ],
        );
      },
    );
  }
}

class HostListTile extends StatelessWidget {
  const HostListTile(this.host);

  final Host host;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: host.ping(),
        builder: (context, snapshot) {
          print(host.host);
          print(snapshot.data);
          print(snapshot.error);

          final hasEither = snapshot.hasData || snapshot.hasError;

          return ListTile(
            title: Text(
              host.label,
              style: TextStyle(
                fontFamily: "Hack",
              ),
            ),
            minLeadingWidth: 24,
            leading: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.language,
                  color: (snapshot.hasData)
                      ? Colors.greenAccent
                      : (snapshot.hasError)
                          ? Colors.redAccent
                          : Colors.grey,
                ),
                if (!hasEither)
                  Container(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                    ),
                  ),
              ],
            ),
            onTap: snapshot.hasData
                ? () async {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) {
                        return HostView(host);
                      },
                    ));
                  }
                : null,
          );
        });
  }
}
