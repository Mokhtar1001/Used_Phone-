/// طلب معاينة في المحل (Store visit).
/// الحالات: pending (مستني تأكيد) / confirmed (متأكد) / completed (اتعملت) / cancelled / no_show (العميل ماجاش)
class InspectionRequest {
  final String id;
  final String productId;
  final String customerId;
  final String status;
  final String? report;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// ميعاد الزيارة (بتوقيت الجهاز). null = طلب قديم من قبل نظام المواعيد
  final DateTime? scheduledAt;

  /// العميل طلب نحجزله التليفون لحد ما يجي
  final bool holdRequested;

  /// الأدمن حجز التليفون فعلًا (حالة المنتج reserved)
  final bool productHeld;

  /// وقت انتهاء حجز التليفون (24 ساعة من وقت الحجز). null = مفيش حجز أو الحجز من غير مدة
  final DateTime? holdExpiresAt;

  final String? customerNote;
  final String? adminNote;

  final String? productNameAr;
  final String? productNameEn;
  final String? productStatus;
  final String? customerName;
  final String? customerPhone;

  InspectionRequest({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.status,
    this.report,
    required this.createdAt,
    this.completedAt,
    this.scheduledAt,
    this.holdRequested = false,
    this.productHeld = false,
    this.holdExpiresAt,
    this.customerNote,
    this.adminNote,
    this.productNameAr,
    this.productNameEn,
    this.productStatus,
    this.customerName,
    this.customerPhone,
  });

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoShow => status == 'no_show';

  /// لسه ممكن يحصل عليه إجراء (مستني تأكيد أو متأكد)
  bool get isActive => isPending || isConfirmed;

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
      scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']).toLocal() : null,
      holdRequested: json['hold_requested'] == true,
      productHeld: json['product_held'] == true,
      holdExpiresAt: json['hold_expires_at'] != null ? DateTime.parse(json['hold_expires_at']).toLocal() : null,
      customerNote: json['customer_note'],
      adminNote: json['admin_note'],
      productNameAr: product?['name_ar'],
      productNameEn: product?['name_en'],
      productStatus: product?['status'],
      customerName: customer?['full_name'],
      customerPhone: customer?['phone'],
    );
  }
}
