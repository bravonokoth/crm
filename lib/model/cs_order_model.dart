import 'package:ClientFlow/model/cs_item_model.dart'; // Import the item model if you have one

class Order {
  final int orderId;
  final String status;
  final String total;
  final double subtotal;
  final String dateCreated;
  final String deliveryDate;
  final String company;
  final String orderNumber;
  final String shippingCity;
  final double price;
  final List items; // Changed to List

  Order({
    required this.orderId,
    required this.status,
    required this.total,
    required this.subtotal,
    required this.dateCreated,
    required this.deliveryDate,
    required this.company,
    required this.orderNumber,
    required this.shippingCity,
    required this.price,
    required this.items,
  });

  factory Order.fromJson(Map json) {
    // Parse the items field
    List itemList = [];
    if (json['items'] != null) {
      itemList = (json['items'] as List).map((itemJson) => OrderItem.fromJson(itemJson)).toList();
    }

    return Order(
      orderId: json['id'],
      status: json['status'] ?? '',
      total: json['total'] ?? '',
      subtotal: json['subtotal']?.toDouble() ?? 0.0,
      dateCreated: json['dateCreated'] ?? '',
      deliveryDate: json['deliveryDate'] ?? '',
      company: json['company'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      shippingCity: json['shippingCity'] ?? '',
      price: json['price']?.toDouble() ?? 0.0,
      items: itemList,
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int itemId;
  final String description;
  final String sku;
  final double rate;
  final int quantity;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.itemId,
    required this.description,
    required this.sku,
    required this.rate,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      itemId: json['item_id'],
      description: json['description'],
      sku: json['sku'],
      rate: (json['rate'] as num).toDouble(),
      quantity: json['quantity'],
    );
  }
}