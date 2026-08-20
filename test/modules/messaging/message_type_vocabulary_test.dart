/// Every message type the server can send must mean something here.
///
/// ## What this caught
///
/// `MessageType` was `{ text, image, system, unknown }` while the backend's
/// `SENDABLE_MESSAGE_TYPES` has carried `text`, `image` and `file` throughout.
/// The mapper's `default` arm turned a `file` message into `unknown` — so a PDF
/// sent from the provider app arrived in the customer's chat as nothing in
/// particular, silently, because a default arm cannot fail.
///
/// ## Why the cases are listed rather than hand-written per test
///
/// A vocabulary written before a case exists cannot grow on its own. The list
/// below is the SERVER's, transcribed from `messagingPolicy.SENDABLE_MESSAGE_TYPES`
/// plus the `system` type the server emits but no client sends. Adding a type
/// there and not here leaves this file asserting an old alphabet — which is why
/// the last test asserts the SIZE of the enum too: a new value cannot be added
/// to `MessageType` without someone deciding what it maps from.
library;

import 'package:client/modules/messaging/data/mappers/message_mapper.dart';
import 'package:client/modules/messaging/data/models/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// The wire values, and what each must become.
///
/// `SENDABLE_MESSAGE_TYPES = ['text', 'image', 'file']`; `system` is emitted by
/// the server for lifecycle events and is not sendable by anyone.
const Map<String, MessageType> kWireVocabulary = {
  'text': MessageType.text,
  'image': MessageType.image,
  'file': MessageType.file,
  'system': MessageType.system,
};

MessageModel _parse(String type) => MessageMapper.fromJson(
      {
        'id': 1,
        'type': type,
        'body': 'x',
        'createdAt': '2026-08-20T09:00:00.000Z',
      },
      conversationId: 77,
    );

void main() {
  group('every type the server sends is understood', () {
    for (final entry in kWireVocabulary.entries) {
      test('"${entry.key}" maps to ${entry.value}', () {
        expect(_parse(entry.key).type, entry.value);
      });
    }

    test('none of them falls through to unknown', () {
      // The failure this replaces: `file` matched no case, hit the default,
      // and became `unknown` with nothing to say so.
      for (final wire in kWireVocabulary.keys) {
        expect(_parse(wire).type, isNot(MessageType.unknown),
            reason: '"$wire" is not in the mapper');
      }
    });
  });

  group('unknown still means unknown', () {
    test('a type this build has never heard of does not crash', () {
      // The default arm is right for a type from a NEWER server. What it must
      // not do is absorb a type this build was supposed to know.
      expect(_parse('hologram').type, MessageType.unknown);
    });

    test('an absent type is unknown rather than assumed to be text', () {
      final parsed = MessageMapper.fromJson(
        {'id': 2, 'body': 'x', 'createdAt': '2026-08-20T09:00:00.000Z'},
        conversationId: 77,
      );
      expect(parsed.type, MessageType.unknown);
    });
  });

  test('the enum has not grown without this file being told', () {
    // The guard that makes the vocabulary above maintainable rather than
    // decorative. `unknown` is the only value with no wire form, so the enum is
    // exactly the vocabulary plus one.
    expect(MessageType.values.length, kWireVocabulary.length + 1,
        reason: 'MessageType gained or lost a value. Add its wire form to '
            'kWireVocabulary, or remove it — a value nothing maps to is a '
            'branch no message can reach.');
    expect(MessageType.values, contains(MessageType.unknown));
  });
}
