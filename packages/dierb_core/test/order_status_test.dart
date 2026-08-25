import 'package:dierb_core/dierb_core.dart';
import 'package:test/test.dart';

void main() {
  test('legacy order statuses remain readable', () {
    expect(OrderStatusCodec.fromStorage('normal'), OrderStatus.waitingMerchantApproval);
    expect(OrderStatusCodec.fromStorage('picking'), OrderStatus.readyForPickup);
    expect(OrderStatusCodec.fromStorage('delivering'), OrderStatus.onTheWay);
    expect(OrderStatusCodec.fromStorage('ended'), OrderStatus.delivered);
  });

  test('new statuses round-trip through storage', () {
    for (final status in OrderStatus.values) {
      expect(OrderStatusCodec.fromStorage(OrderStatusCodec.toStorage(status)), status);
    }
  });
}
