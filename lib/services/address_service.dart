import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/address.dart';

/// عناوين العميل (جدول addresses، لحد عنوانين - مفروض من الداتابيز)
class AddressService {
  final _client = Supabase.instance.client;

  Future<List<Address>> getMyAddresses(String userId) async {
    final data = await _client.from('addresses').select().eq('user_id', userId).order('created_at', ascending: true);
    return (data as List).map((e) => Address.fromJson(e as Map)).toList();
  }

  /// بيضيف (لو من غير id) أو بيعدّل. بيرمي PostgrestException برسالة address_limit لو عنده عنوانين بالفعل.
  Future<Address> save(String userId, Address address) async {
    if (address.id == null) {
      final row = await _client.from('addresses').insert({...address.toJson(), 'user_id': userId}).select().single();
      return Address.fromJson(row);
    }
    final row = await _client.from('addresses').update(address.toJson()).eq('id', address.id!).select().single();
    return Address.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('addresses').delete().eq('id', id);
  }

  /// لو العميل كتب عنوان وقت التسجيل، بيتحفظ مؤقتًا في user metadata (لأن مفيش جلسة قبل تأكيد الإيميل).
  /// أول ما يسجل دخول بننقله لجدول العناوين مرة واحدة.
  Future<void> importPendingSignupAddress() async {
    final user = _client.auth.currentUser;
    final pending = user?.userMetadata?['pending_address'];
    if (user == null || pending is! Map) return;

    try {
      final existing = await _client.from('addresses').select('id').eq('user_id', user.id).limit(1);
      if ((existing as List).isEmpty) {
        await _client.from('addresses').insert({...Address.fromJson(pending).toJson(), 'user_id': user.id});
      }
      // نفضّي القيمة عشان ماتتنقلش تاني
      await _client.auth.updateUser(UserAttributes(data: {'pending_address': ''}));
    } catch (_) {
      // مش حرج: العميل يقدر يضيف عنوانه وقت الشراء
    }
  }
}
