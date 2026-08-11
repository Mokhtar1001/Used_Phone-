class Review {
  final String id;
  final String productId;
  final String customerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? customerName;

  Review({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.customerName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      productId: json['product_id'],
      customerId: json['customer_id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      customerName: json['profiles']?['full_name'],
    );
  }
}
