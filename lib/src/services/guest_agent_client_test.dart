import 'package:flutter_test/flutter_test.dart';
import 'guest_agent_client.dart';

void main() {
  group('GuestAgentClient', () {
    test('uses default timeout of 5 seconds', () {
      final client = GuestAgentClient('/tmp/qga.sock');
      expect(client.timeout, equals(const Duration(seconds: 5)));
    });

    test('accepts custom timeout', () {
      final client = GuestAgentClient('/tmp/qga.sock', timeout: const Duration(seconds: 10));
      expect(client.timeout, equals(const Duration(seconds: 10)));
    });

    test('accepts TCP port for SLiRP-based connections', () {
      final client = GuestAgentClient('/unused', tcpPort: 2244);
      expect(client.tcpPort, equals(2244));
    });
  });
}