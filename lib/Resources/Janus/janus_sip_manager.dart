import 'package:rise/Controllers/StorageController.dart';
import 'janus_client.dart';


class JanusSipManager {
  JanusSession? _session; // Add a private field to store the session instance
  JanusSipPlugin? _sip;

  // Private constructor to prevent direct instantiation
  JanusSipManager._();

  static final JanusSipManager _instance = JanusSipManager._();

  static JanusSipManager get instance => _instance;

  Future<void> initializeSip() async {
    final gateway = await storageController.getData("gateway");
    if (_sip == null) {
      final ws = WebSocketJanusTransport(url: gateway);
      final j = JanusClient(transport: ws, iceServers: null, isUnifiedPlan: true);
      _session = await j.createSession(); // Store the session instance
      _sip = await _session!.attach<JanusSipPlugin>();
    }
  }

  JanusSipPlugin? get sipInstance => _sip;
  JanusSession? get sessionInstance => _session; // Getter for the session instance
}
