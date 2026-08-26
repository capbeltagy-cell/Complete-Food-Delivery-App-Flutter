enum OrderStatus {
  received,
  waitingMerchantApproval,
  accepted,
  preparing,
  readyForPickup,
  pickedUpByRider,
  onTheWay,
  delivered,
  rejected,
  cancelled,
}

extension OrderStatusText on OrderStatus {
  String get labelAr {
    switch (this) {
      case OrderStatus.received: return 'تم استلام الطلب';
      case OrderStatus.waitingMerchantApproval: return 'بانتظار قبول المتجر';
      case OrderStatus.accepted: return 'تم القبول';
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
}

abstract class OrderStatusCodec {
  static OrderStatus fromStorage(Object? value) {
    final raw = value?.toString();
    switch (raw) {
      case 'normal': return OrderStatus.waitingMerchantApproval;
      case 'picking': return OrderStatus.readyForPickup;
      case 'delivering': return OrderStatus.onTheWay;
      case 'ended': return OrderStatus.delivered;
      default:
        return OrderStatus.values.firstWhere((status) => status.name == raw, orElse: () => OrderStatus.received);
    }
  }

  static String toStorage(OrderStatus status) => status.name;
}
