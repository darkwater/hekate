import 'package:flutter/material.dart';
import 'package:hekate/host.dart';

class HostView extends StatelessWidget {
  final Host host;

  HostView(this.host);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          host.label,
          style: TextStyle(
            fontFamily: "Hack",
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<SystemInfo>(
        stream: (() async* {
          while (true) {
            yield await host.systemInfo();
            await Future.delayed(Duration(seconds: 5));
          }
        })(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                softWrap: true,
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final systemInfo = snapshot.data!;

          return ListView(
            children: [
              Container(
                height: 64 + 24 * 2,
                child: Row(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Container(
                          width: 64,
                          height: 64,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: systemInfo.currentLoad,
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation(Colors.blue),
                              ),
                              Center(
                                child: Text(
                                  "${(systemInfo.currentLoad * 100).round()}%",
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Text(
                                "Mem: ${(systemInfo.memoryInfo.physUsed / (1024 * 1024) * 10).round() / 10} / " +
                                    "${(systemInfo.memoryInfo.physTotal / (1024 * 1024) * 10).round() / 10} GB",
                                textScaleFactor: 1.2,
                                textAlign: TextAlign.start,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 24,
                              right: 24,
                              top: 16,
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  height: 8,
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                                LinearProgressIndicator(
                                  minHeight: 4,
                                  value: (systemInfo.memoryInfo.physUsed +
                                          systemInfo.memoryInfo.physShared +
                                          systemInfo.memoryInfo.physCache) /
                                      systemInfo.memoryInfo.physTotal,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.orange.withOpacity(0.5)),
                                ),
                                LinearProgressIndicator(
                                  minHeight: 4,
                                  value: (systemInfo.memoryInfo.physUsed +
                                          systemInfo.memoryInfo.physShared) /
                                      systemInfo.memoryInfo.physTotal,
                                  backgroundColor: Colors.transparent,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.blue),
                                ),
                                LinearProgressIndicator(
                                  minHeight: 8,
                                  value: systemInfo.memoryInfo.physUsed /
                                      systemInfo.memoryInfo.physTotal,
                                  backgroundColor: Colors.transparent,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.lightGreen),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              for (var disk in systemInfo.diskUsage)
                ListTile(
                  minLeadingWidth: 32,
                  leading: Icon(Icons.storage),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(disk.device),
                          Expanded(
                            child: Text(
                              "${((disk.total - disk.used) / 1024 / 1024 * 10).round() / 10} GB free",
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 8),
                      LinearProgressIndicator(
                        value: disk.used / disk.total,
                        backgroundColor:
                            Colors.deepPurpleAccent.withOpacity(0.2),
                        valueColor:
                            AlwaysStoppedAnimation(Colors.deepPurpleAccent),
                      ),
                    ],
                  ),
                ),
              Divider(),
            ],
          );
        },
      ),
    );
  }
}
