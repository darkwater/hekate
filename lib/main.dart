import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';

import 'host.dart';
import 'hostView/hostView.dart';

late final StreamingSharedPreferences preferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  preferences = await StreamingSharedPreferences.instance;

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
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: "Add host",
            onPressed: () {
              addHost(context);
            },
          ),
        ],
      ),
      body: Center(
        child: PreferenceBuilder<List<Host>>(
          preference: preferences.getCustomValue(
            "hosts",
            defaultValue: [],
            adapter: Host.prefAdapter,
          ),
          builder: (context, hosts) => ListView.builder(
            itemCount: hosts.length,
            itemBuilder: (context, idx) {
              return HostListTile(hosts[idx]);
            },
          ),
        ),
      ),
    );
  }

  Future<void> addHost(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>();

        final ctrlName = TextEditingController();
        final ctrlHost = TextEditingController();
        final ctrlPort = TextEditingController(text: "8080");
        final ctrlPassword = TextEditingController();

        return Form(
          key: formKey,
          child: AlertDialog(
            title: Text("Add host"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: ctrlName,
                  autofocus: true,
                  decoration: InputDecoration(labelText: "Name"),
                  textInputAction: TextInputAction.next,
                  validator: (input) =>
                      input?.isEmpty == true ? "Please enter a name" : null,
                ),
                TextFormField(
                  controller: ctrlHost,
                  decoration: InputDecoration(labelText: "Host"),
                  textInputAction: TextInputAction.next,
                  validator: (input) =>
                      input?.isEmpty == true ? "Please enter a host" : null,
                ),
                TextFormField(
                  controller: ctrlPort,
                  decoration: InputDecoration(labelText: "Port"),
                  textInputAction: TextInputAction.next,
                  validator: (input) {
                    final port = int.tryParse(input ?? "");
                    if (port == null) {
                      return "Please enter a valid port number";
                    } else if (port > 65535) {
                      return "Port numbers don't go past 65535";
                    }
                  },
                ),
                TextFormField(
                  controller: ctrlPassword,
                  decoration: InputDecoration(labelText: "Password"),
                  obscureText: true,
                  onEditingComplete: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final hosts = preferences
                        .getCustomValue<List<Host>>(
                          "hosts",
                          defaultValue: [],
                          adapter: Host.prefAdapter,
                        )
                        .getValue();

                    hosts.add(Host(
                      label: ctrlName.text,
                      host: ctrlHost.text,
                      port: int.parse(ctrlPort.text),
                      password: ctrlPassword.text,
                    ));

                    await preferences.setCustomValue("hosts", hosts,
                        adapter: Host.prefAdapter);

                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
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
    final node = FocusNode();

    return FutureBuilder<dynamic>(
      future: host.ping(),
      builder: (context, snapshot) {
        print(host.host);
        print(snapshot.data);
        print(snapshot.error);

        final hasEither = snapshot.hasData || snapshot.hasError;

        return ListTile(
          focusNode: node,
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
          onLongPress: () async {
            final RenderBox tile = context.findRenderObject()! as RenderBox;
            final RenderBox overlay = Navigator.of(context)
                .overlay!
                .context
                .findRenderObject()! as RenderBox;

            final RelativeRect position = RelativeRect.fromRect(
              Rect.fromPoints(
                tile.localToGlobal(Offset.fromDirection(0), ancestor: overlay),
                tile.localToGlobal(tile.size.bottomRight(Offset.zero),
                    ancestor: overlay),
              ),
              Offset.zero & overlay.size,
            );

            final result = await showMenu(
              context: context,
              position: position,
              items: [
                PopupMenuItem(
                  child: Text("Delete"),
                  value: "delete",
                ),
              ],
            );

            if (result == "delete") {
              final hosts = preferences
                  .getCustomValue<List<Host>>(
                    "hosts",
                    defaultValue: [],
                    adapter: Host.prefAdapter,
                  )
                  .getValue();

              hosts.removeWhere((el) => el.host == host.host);

              await preferences.setCustomValue("hosts", hosts,
                  adapter: Host.prefAdapter);
            }
          },
        );
      },
    );
  }
}
