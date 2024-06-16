part of '../../client.dart';

/// Control Multiple Clients
class ClientPool {
  /// All Clients
  List<Client> clients = [];

  /// Adds a Client using the [config].
  int addClient(Configuration config, {bool connect = false}) {
    var client =
        Client(config, parser: RegexIrcParser()); // Provide a valid parser
    clients.add(client);
    if (connect) {
      client.connect();
    }
    return clients.indexOf(client);
  }

  Client clientAt(int position) => clients[position];

  int idOf(Client client) => clients.indexOf(client);

  Client operator [](int id) => clientAt(id);

  void connectAll() => forEach((client) => client.connect());
  void disconnectAll([String reason = '']) =>
      forEach((client) => client.disconnect(reason: reason));
  void sendMessage(String target, String message) =>
      forEach((client) => client.sendMessage(target, message));
  void register<T>(Function(T event) handler) =>
      forEach((client) => client.register(handler, intent: ''));
  void forEach(void Function(Client client) action) => clients.forEach(action);
}
