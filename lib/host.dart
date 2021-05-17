import 'dart:io';

import 'package:http/io_client.dart' as http;
import 'dart:convert';

class Host {
  final String label;
  final String host;
  final int port;
  final String password;

  http.IOClient httpClient;

  Host({
    required this.label,
    required this.host,
    required this.password,
    this.port = 8080,
  }) : httpClient = http.IOClient(HttpClient()
          ..badCertificateCallback =
              (X509Certificate cert, String host, int port) => true);

  Uri _at(String path) {
    return Uri(
      host: host,
      port: port,
      scheme: "https",
      path: path,
      userInfo: ":$password",
    );
  }

  Future<bool> ping() async {
    final res = await httpClient.get(_at("/ping"));
    if (res.statusCode == 200) {
      return true;
    }

    throw "failed ping";
  }

  Future<SystemInfo> systemInfo() async {
    final res = await httpClient.get(_at("/system/info"));
    if (res.statusCode == 200) {
      return SystemInfo.fromMap(json.decode(res.body));
    }

    throw "failed ping";
  }
}

class SystemInfo {
  final double currentLoad;
  final SystemInfoMemory memoryInfo;
  final List<SystemInfoDisk> diskUsage;

  SystemInfo({
    required this.currentLoad,
    required this.memoryInfo,
    required this.diskUsage,
  });

  factory SystemInfo.fromMap(Map<String, dynamic> m) {
    return SystemInfo(
      currentLoad: m["current_load"],
      memoryInfo: SystemInfoMemory.fromMap(m["memory_info"]),
      diskUsage: m["disk_usage"]
          .map<SystemInfoDisk>((d) => SystemInfoDisk.fromMap(d))
          .toList(),
    );
  }
}

class SystemInfoMemory {
  final int physTotal;
  final int physUsed;
  final int physShared;
  final int physCache;
  final int swapTotal;
  final int swapUsed;

  SystemInfoMemory({
    required this.physTotal,
    required this.physUsed,
    required this.physShared,
    required this.physCache,
    required this.swapTotal,
    required this.swapUsed,
  });

  factory SystemInfoMemory.fromMap(Map<String, dynamic> m) {
    return SystemInfoMemory(
      physTotal: m["phys_total"],
      physUsed: m["phys_used"],
      physShared: m["phys_shared"],
      physCache: m["phys_cache"],
      swapTotal: m["swap_total"],
      swapUsed: m["swap_used"],
    );
  }
}

class SystemInfoDisk {
  final String device;
  final int total;
  final int used;

  SystemInfoDisk({
    required this.device,
    required this.total,
    required this.used,
  });

  factory SystemInfoDisk.fromMap(Map<String, dynamic> m) {
    return SystemInfoDisk(
      device: m["device"],
      total: m["total"],
      used: m["used"],
    );
  }
}
