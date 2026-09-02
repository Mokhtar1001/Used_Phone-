class InspectionRequest {
  final String id;
  final String productId;
  final String customerId;
  final String status; // pending / completed
  final String? report;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? productNameAr;
  final String? productNameEn;
  final String? customerName;

  InspectionRequest({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.status,
    this.report,
    required this.createdAt,
    this.completedAt,
    this.productNameAr,
    this.productNameEn,
    this.customerName,
  });

  bool get isCompleted => status == 'completed';

  String productName(bool isArabic) =>
      (isArabic ? productNameAr : productNameEn) ?? (isArabic ? 'منتج محذوف' : 'Deleted product');

  factory InspectionRequest.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    final customer = json['profiles'] as Map<String, dynamic>?;

    return InspectionRequest(
      id: json['id'],
      productId: json['product_id'],
      customerId: json['customer_id'],
      status: json['status'] ?? 'pending',
      report: json['report'],
      createdAt: DateTime.parse(json['created_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      productNameAr: product?['name_ar'],
      productNameEn: product?['name_en'],
      customerName: customer?['full_name'],
    );
  }
}
