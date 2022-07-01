// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

// ignore_for_file: require_trailing_commas

part of firebase_auth_dart;

/// A storage box is a container for key-value pairs of data
/// which exists in one box with specific name.
///
/// To get or create a new box, first initialize an instance
/// with a name, then use the methods provided for that box,
/// if the box doesn't exist, it will be created, if it exists
/// data will be written to the existing one.
class StorageBox<T extends Object> {
  // ignore: public_member_api_docs
  StorageBox._(this._name);

  /// Get a [StorageBox] instance for a given name.
  static StorageBox instanceOf([String name = 'user']) {
    if (!_instances.containsKey(name)) {
      _instances.addAll({name: StorageBox._(name)});
    }
    return _instances[name]!;
  }

  static final Map<String, StorageBox> _instances = {};

  /// The name of the box which you want to create or get.
  final String _name;

  bool _isTizen() {
    final file = File('/etc/tizen-release');
    return file.existsSync();
  }

  // unused for now
  Future<String> _getTizenDataPath() async {
    final packageName = (await PackageInfo.fromPlatform()).packageName;
    final path = '/opt/usr/home/owner/apps_rw/$packageName/data/';

    return path;
  }

  Future<File> get _file async {
    /// `APPDATA` for windows, `HOME` for linux and mac
    final _env = Platform.environment;
    final _sep = Platform.pathSeparator;

    late String _home;

    if (Platform.isLinux || Platform.isMacOS) {
      // ignore: cast_nullable_to_non_nullable
      _home = _env['HOME'] as String;
    }

    if (Platform.isWindows) {
      // ignore: cast_nullable_to_non_nullable
      _home = _env['APPDATA'] as String;
    }

    if (_isTizen()) {
      // temporary solution, eventually we should use
      // path_provider.getApplicationDocumentsDirectory(),
      // like in _getTizenDataPath()
      _home = await _getTizenDataPath();
    }

    final _path = '$_home$_sep.firebase-auth$_sep$_name.json';

    return File(_path);
  }

  /// Store the key-value pair in the box with [_name], if key already
  /// exists the value will be overwritten.
  Future putValue(String key, T? value) async {
    final file = await _file;
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    final contentMap = await _readFile();

    if (value != null) {
      contentMap[key] = value;
    } else {
      contentMap.remove(key);
    }

    if (contentMap.isEmpty) {
      file.deleteSync(recursive: true);
    } else {
      file.writeAsStringSync(jsonEncode(contentMap));
    }
  }

  /// Get the value for a specific key, if no such key exists, or no such box with [_name]
  /// [StorageBoxException] will be thrown.
  Future<T> getValue(String key) async {
    try {
      final file = await _file;
      final contentText = file.readAsStringSync();
      final Map<String, dynamic> content = jsonDecode(contentText);

      if (!content.containsKey(key)) {
        throw StorageBoxException('Key $key does not exist.');
      }

      return content[key];
    } on FileSystemException {
      throw StorageBoxException('Box $_name does not exist, '
          'to create one, add some value using "putValue".');
    }
  }

  Future<Map<String, dynamic>> _readFile() async {
    final file = await _file;
    final contentText = file.readAsStringSync();

    if (contentText.isEmpty) {
      return {};
    }

    final content = json.decode(contentText) as Map<String, dynamic>;

    return content;
  }
}

/// Throw when there's an error with [StorageBox] methods.
class StorageBoxException implements Exception {
  // ignore: public_member_api_docs
  StorageBoxException([this.message]);

  /// Message describing the error.
  final String? message;
}
