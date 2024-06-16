part of '../../client.dart';

/// An IRC Channel
class Channel extends Entity {
  /// Client associated with the channel
  final Client client;

  /// Channel Name (Including the #)
  @override
  final String name;

  /// Storage for data about a channel.
  /// Note that this doesn't persist when the client leaves the channel.
  final Map<String, dynamic> metadata;

  /// Channel Operators
  @override
  final Set<User> ops = <User>{};

  /// Channel Half-Ops
  @override
  final Set<User> halfops = <User>{};

  /// Channel Voices
  @override
  final Set<User> voices = <User>{};

  /// Channel Members
  @override
  final Set<User> members = <User>{};

  /// Channel Owners (Not Supported on all Servers)
  @override
  final Set<User> owners = <User>{};

  /// Channel topic
  late final String _topic;

  /// Banned Hostmasks
  final List<GlobHostmask> bans = [];

  /// Modes set on the Channel.
  final Mode mode = Mode.empty();

  /// Channel topic
  String get topic => _topic;

  /// User who changed the topic last.
  String get topicUser => _topicUser;

  /// Change the topic for the Channel.
  set topic(String topic) {
    if (client.supported.containsKey('TOPICLEN')) {
      var max = client.supported['TOPICLEN'];
      if (topic.length > max) {
        throw ArgumentError.value(topic,
            'length is >${max}, which is the maximum topic length set by the server.');
      }
    }

    client.send('TOPIC ${name} :${topic}');
  }

  /// User who changed the topic last.
  late final String _topicUser;

  /// Invite a user to the Channel.
  void invite(User user) {
    client.invite(user, name);
  }

  /// Get all users for the Channel.
  @override
  Set<User> get allUsers {
    var all = <User>{}
      ..addAll(ops)
      ..addAll(voices)
      ..addAll(members)
      ..addAll(owners)
      ..addAll(halfops);
    return all;
  }

  /// Creates a new channel associated with [client] named [name].
  Channel(this.client, this.name, this._topic, this._topicUser,
      {required String id})
      : metadata = {};

  /// Sends [message] as a channel message
  void sendMessage(String message) => client.sendMessage(name, message);

  /// Sends [message] as a channel notice
  void sendNotice(String message) => client.sendNotice(name, message);

  /// Sets +o (Channel Operator) mode on [user]
  void op(User user) => setMode('+o', user);

  /// Sets -o (Remove Channel Operator) mode on [user]
  void deop(User user) => setMode('-o', user);

  /// Sets +v (Channel Voice) mode on [user]
  void voice(User user) => setMode('+v', user);

  /// Sets -v (Remove Channel Voice) mode on [user]
  void devoice(User user) => setMode('-v', user);

  /// Sets +b (Ban) mode on [user]
  void ban(User user) => setMode('+b', user);

  /// Sets -b (Remove Ban) mode on [user]
  void unban(User user) => setMode('-b', user);

  /// Kicks [user] from channel with optional [reason].
  void kick(User user, [String? reason]) => client.kick(this, user, reason);

  /// Sets +b on [user] then kicks [user] with the specified [reason]
  void kickban(User user, [String? reason]) {
    ban(user);
    kick(user, reason);
  }

  /// Sets +h (Half-Op) mode on [user]
  void hop(User user) => setMode('+h', user);

  /// Sets -h (Remove Half-Op) mode on [user]
  void dehop(User user) => setMode('-h', user);

  /// Sends [msg] as a channel action.
  void sendAction(String msg) => client.sendAction(name, msg);

  /// Reloads the Ban List.
  void reloadBans() {
    bans.clear();
    setMode('+b');
  }

  /// Sets the Mode on the Channel or if the user if [user] is specified.
  void setMode(String mode, [User? user]) {
    client.send('MODE ${name} ${mode} ${user}');
  }

  /// Checks whether a user is inside this channel.
  bool hasUser(User user) {
    return ops.contains(user) ||
        halfops.contains(user) ||
        voices.contains(user) ||
        members.contains(user) ||
        owners.contains(user);
  }

  bool _userListHas(String name, Set<User> users) {
    return users.any((user) => user.name == name);
  }

  bool hasUserWithName(String name) {
    return _userListHas(name, ops) ||
        _userListHas(name, halfops) ||
        _userListHas(name, voices) ||
        _userListHas(name, members) ||
        _userListHas(name, owners);
  }

  void _dropFromUserList(String nickname) {
    ops.removeWhere((user) => user.name == nickname);
    halfops.removeWhere((user) => user.name == nickname);
    voices.removeWhere((user) => user.name == nickname);
    members.removeWhere((user) => user.name == nickname);
    owners.removeWhere((user) => user.name == nickname);
  }

  /// Compares [object] to this. Only true if channels names are equal.
  @override
  bool operator ==(Object object) =>
      object is Channel &&
      identical(client, object.client) &&
      name == object.name;

  Future<Mode> getMode() async {
    client.send('MODE ${name}', now: true);
    await Future.delayed(const Duration(seconds: 2));
    return mode;
  }

  void reloadTopic() {
    client.send('TOPIC ${name}');
  }
}
