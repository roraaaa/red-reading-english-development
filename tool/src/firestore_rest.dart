import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'firestore_values.dart';

/// The small part of the Firestore REST API the content uploader needs.
class FirestoreRest {
  FirestoreRest(this._client, this.projectId);

  /// Firestore accepts at most 500 writes in one commit.
  static const maxWritesPerCommit = 500;

  final http.Client _client;
  final String projectId;

  String get _documentsUrl => 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  String documentName(String path) => 'projects/$projectId/databases/(default)/documents/$path';

  /// IDs of every document in a top-level [collection].
  Future<Set<String>> listDocumentIds(String collection) async {
    final ids = <String>{};
    String? pageToken;
    do {
      final uri = Uri.parse('$_documentsUrl/$collection').replace(
        queryParameters: {
          'pageSize': '300',
          'mask.fieldPaths': 'id',
          'pageToken': ?pageToken,
        },
      );
      final response = await _client.get(uri);
      _check(response);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      for (final doc in (body['documents'] as List?) ?? const []) {
        ids.add(((doc as Map)['name'] as String).split('/').last);
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);
    return ids;
  }

  Map<String, dynamic> setWrite(String path, Map<String, dynamic> data) => {
    'update': {'name': documentName(path), 'fields': FirestoreValues.encodeFields(data)},
  };

  Map<String, dynamic> deleteWrite(String path) => {'delete': documentName(path)};

  /// Applies [writes] atomically. Throws if there are too many for one commit.
  Future<void> commit(List<Map<String, dynamic>> writes) async {
    if (writes.length > maxWritesPerCommit) {
      throw ArgumentError('Too many writes for one commit (${writes.length}).');
    }
    final response = await _client.post(
      Uri.parse('$_documentsUrl:commit'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'writes': writes}),
    );
    _check(response);
  }

  void _check(http.Response response) {
    if (response.statusCode >= 300) {
      throw HttpException('Firestore request failed (${response.statusCode}): ${response.body}');
    }
  }
}
