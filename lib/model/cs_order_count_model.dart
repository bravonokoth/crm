class OrderCount {
  final int totalOrders;
  final int processingOrders;
  final int deliveredOrders;
  final int draftOrders;
  final int returnOrders;

  OrderCount({
    required this.totalOrders,
    required this.processingOrders,
    required this.deliveredOrders,
    required this.draftOrders,
    required this.returnOrders,
  });

  factory OrderCount.fromJson(Map<String, dynamic> json) {
    return OrderCount(
      totalOrders: json['total_orders'] ?? 0,
      processingOrders: json['processing_orders'] ?? 0,
      deliveredOrders: json['finished_orders'] ?? 0,
      draftOrders: json['draft_orders'] ?? 0,
      returnOrders: json['returned_orders'] ?? 0,
    );
  }

}
