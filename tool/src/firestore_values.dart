/// Converts plain JSON-like Dart values into the typed value format used by
/// the Firestore REST API.
abstract final class FirestoreValues {
  static Map<String, dynamic> encodeFields(Map<String, dynamic> map) => {
    for (final entry in map.entries) entry.key: encode(entry.value),
  };

  static Map<String, dynamic> encode(Object? value) => switch (value) {
    null => {'nullValue': null},
    bool b => {'booleanValue': b},
    int i => {'integerValue': '$i'},
    double d => {'doubleValue': d},
    String s => {'stringValue': s},
    List list => {
      'arrayValue': {
        'values': [for (final item in list) _arrayItem(item)],
      },
    },
    Map map => {
      'mapValue': {'fields': encodeFields(Map<String, dynamic>.from(map))},
    },
    _ => throw ArgumentError('Cannot store a ${value.runtimeType} in Firestore.'),
  };

  static Map<String, dynamic> _arrayItem(Object? item) {
    if (item is List) {
      throw ArgumentError('Firestore cannot store a list inside a list: $item');
    }
    return encode(item);
  }
}
