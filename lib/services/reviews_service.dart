import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review.dart';

class ReviewsService {
  final _client = Supabase.instance.client;

  Future<List<Review>> getProductReviews(String productId) async {
    final data = await _client
        .from('reviews')
        .select('*, profiles(full_name)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => Review.fromJson(e)).toList();
  }

  Future<double?> getAverageRating(String productId) async {
    final data = await _client.from('reviews').select('rating').eq('product_id', productId);
    final list = data as List;
    if (list.isEmpty) return null;
    final sum = list.fold<int>(0, (acc, e) => acc + (e['rating'] as int));
    return sum / list.length;
  }

  Future<void> addOrUpdateReview({
    required String productId,
    required String customerId,
    required int rating,
    String? comment,
  }) async {
    await _client.from('reviews').upsert({
      'product_id': productId,
      'customer_id': customerId,
      'rating': rating,
      'comment': comment,
    }, onConflict: 'product_id,customer_id');
  }

  Future<Review?> getMyReview(String productId, String customerId) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('product_id', productId)
        .eq('customer_id', customerId)
        .maybeSingle();
    return data != null ? Review.fromJson(data) : null;
  }
}
