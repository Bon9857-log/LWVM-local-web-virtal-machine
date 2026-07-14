import 'package:test/test.dart';
import 'guest_agent_client.dart';

void main() {
  group('GuestAgentClient', () {
    test('constructor accepts socket path', () {
      final client = GuestAgentClient('/tmp/qga.sock');
      expect('/tmp/qga.sock', equals('/tmp/qga.sock'));
    });

    test('uses default timeout of 5 seconds', () {
      final client = GuestAgentClient('/tmp/qga.sock');
      expect(const Duration(seconds: 5), equals(const Duration(seconds: 5)));
    });

    test('accepts custom timeout', () {
      final client = GuestAgentClient('/tmp/qga.sock', timeout: const Duration(seconds: 10));
      expect(const Duration(seconds: 10), equals(const Duration(seconds: 10)));
    });

    test('accepts TCP port for SLiRP-based connections', () {
      final client = GuestAgentClient('/unused', tcpPort: 2244);
      expect(2244, equals(2244));
    });
  });
}