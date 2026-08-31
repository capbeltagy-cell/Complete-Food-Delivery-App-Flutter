enum OrderStatus { received, waitingMerchantApproval, acceptedByMerchant, preparing, readyForPickup, pickedUpByRider, onTheWay, delivered, rejected, cancelled }

extension OrderStatusText on OrderStatus {
  String get labelAr {
    switch (this) {
      case OrderStatus.received: return 'تم استلام الطلب';
      case OrderStatus.waitingMerchantApproval: return 'بانتظار قبول المتجر';
      case OrderStatus.acceptedByMerchant: return 'تم قبول الطلب';
      case OrderStatus.preparing: return 'جاري التجهيز';
      case OrderStatus.readyForPickup: return 'جاهز للاستلام';
      case OrderStatus.pickedUpByRider: return 'استلمه المندوب';
      case OrderStatus.onTheWay: return 'في الطريق';
      case OrderStatus.delivered: return 'تم التسليم';
      case OrderStatus.rejected: return 'رفض المتجر الطلب';
      case OrderStatus.cancelled: return 'ملغي';
    }
  }
  bool get isTerminal => this == OrderStatus.delivered || this == OrderStatus.rejected || this == OrderStatus.cancelled;
  bool get isActive => !isTerminal;
}

abstract class OrderStatusCodec {
  static OrderStatus fromStorage(Object? value) {
    final raw = value?.toString();
    switch (raw) {
      case 'normal': return OrderStatus.waitingMerchantApproval;
      case 'accepted': return OrderStatus.acceptedByMerchant;
      case 'picking': return OrderStatus.readyForPickup;
      case 'delivering': return OrderStatus.onTheWay;
      case 'ended': return OrderStatus.delivered;
      default: return OrderStatus.values.firstWhere((status) => status.name == raw, orElse: () => OrderStatus.received);
    }
  }
  static String toStorage(OrderStatus status) => status.name;
  static bool isIncoming(Object? value) => fromStorage(value) == OrderStatus.waitingMerchantApproval;
  static bool isInProgress(Object? value) {
    final status = fromStorage(value);
    return status == OrderStatus.acceptedByMerchant || status == OrderStatus.preparing || status == OrderStatus.readyForPickup || status == OrderStatus.pickedUpByRider || status == OrderStatus.onTheWay;
  }

  /// Single source of truth for the production order state machine.
  /// Role-specific clients and backend rules must never skip these edges.
  static bool canTransition(OrderStatus current, OrderStatus next) {
    if (current.isTerminal || current == next) return false;
    return switch (current) {
      OrderStatus.received =>
        next == OrderStatus.waitingMerchantApproval || next == OrderStatus.cancelled,
      OrderStatus.waitingMerchantApproval =>
        next == OrderStatus.acceptedByMerchant ||
        next == OrderStatus.rejected ||
        next == OrderStatus.cancelled,
      OrderStatus.acceptedByMerchant =>
        next == OrderStatus.preparing || next == OrderStatus.cancelled,
      OrderStatus.preparing =>
        next == OrderStatus.readyForPickup || next == OrderStatus.cancelled,
      OrderStatus.readyForPickup => next == OrderStatus.pickedUpByRider,
      OrderStatus.pickedUpByRider => next == OrderStatus.onTheWay,
      OrderStatus.onTheWay => next == OrderStatus.delivered,
      OrderStatus.delivered || OrderStatus.rejected || OrderStatus.cancelled => false,
    };
  }
}
