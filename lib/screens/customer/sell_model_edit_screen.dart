import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/sell_models.dart';
import '../../providers/locale_provider.dart';
import '../../services/sell_service.dart';

class _StorageRow {
  final TextEditingController storage;
  final TextEditingController price;
  _StorageRow({String storage = '', String price = ''})
      : storage = TextEditingController(text: storage),
        price = TextEditingController(text: price);

  void dispose() {
    storage.dispose();
    price.dispose();
  }
}

/// إضافة / تعديل موديل أيفون: الاسم + الصورة + المساحات وسعر كل مساحة.
/// لازم مساحة واحدة على الأقل بسعرها - عشان الزبون بيختار المساحة وهو بيبيع.
class SellModelEditScreen extends StatefulWidget {
  final SellModel? model;
  const SellModelEditScreen({super.key, this.model});

  @override
  State<SellModelEditScreen> createState() => _SellModelEditScreenState();
}

class _SellModelEditScreenState extends State<SellModelEditScreen> {
  static const _suggestions = ['64GB', '128GB', '256GB', '512GB', '1TB'];

  final _service = SellService();
  final _nameController = TextEditingController();
  final List<_StorageRow> _rows = [];

  String? _imageUrl;
  XFile? _newImage;
  Uint8List? _newBytes;
  bool _isActive = true;
  bool _saving = false;
  bool _ar = false;

  bool get _isEditing => widget.model != null;
  String _t(String ar, String en) => sellTr(_ar, ar, en);

  @override
  void initState() {
    super.initState();
    final m = widget.model;
    if (m != null) {
      _nameController.text = m.name;
      _imageUrl = m.imageUrl;
      _isActive = m.isActive;
      for (final s in m.storages) {
        _rows.add(_StorageRow(storage: s.storage, price: s.basePrice.toStringAsFixed(0)));
      }
    }
    if (_rows.isEmpty) _rows.add(_StorageRow());
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _newImage = picked;
      _newBytes = bytes;
    });
  }

  void _addSuggestion(String storage) {
    final exists = _rows.any((r) => r.storage.text.trim().toLowerCase() == storage.toLowerCase());
    if (exists) return;
    setState(() {
      // لو فيه صف فاضي، املاه بدل ما نضيف صف جديد
      final empty = _rows.where((r) => r.storage.text.trim().isEmpty && r.price.text.trim().isEmpty);
      if (empty.isNotEmpty) {
        empty.first.storage.text = storage;
      } else {
        _rows.add(_StorageRow(storage: storage));
      }
    });
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack(_t('اكتب اسم الموديل', 'Enter the model name'));
      return;
    }

    final storages = <SellStorage>[];
    final seen = <String>{};
    for (final r in _rows) {
      final storage = r.storage.text.trim();
      final price = double.tryParse(r.price.text.trim());
      if (storage.isEmpty && r.price.text.trim().isEmpty) continue; // صف فاضي - تجاهله
      if (storage.isEmpty || price == null || price <= 0) {
        _snack(_t('كل مساحة لازم يكون ليها اسم وسعر أكبر من صفر', 'Every storage needs a name and a price above zero'));
        return;
      }
      if (!seen.add(storage.toLowerCase())) {
        _snack(_t('المساحة "$storage" متكررة', 'Storage "$storage" is duplicated'));
        return;
      }
      storages.add(SellStorage(storage: storage, basePrice: price));
    }
    if (storages.isEmpty) {
      _snack(_t('لازم تضيف مساحة واحدة على الأقل بسعرها', 'Add at least one storage option with its price'));
      return;
    }

    setState(() => _saving = true);
    try {
      var imageUrl = _imageUrl;
      if (_newImage != null) imageUrl = await _service.uploadModelImage(_newImage!);

      await _service.saveModel(
        id: widget.model?.id,
        name: name,
        imageUrl: imageUrl,
        isActive: _isActive,
        storages: storages,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _snack(_t('حصل خطأ أثناء الحفظ', 'Something went wrong while saving'));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _ar = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? _t('تعديل موديل', 'Edit model') : _t('إضافة موديل', 'Add model'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // الصورة
              Center(
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppTheme.offWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.lightGray),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _newBytes != null
                          ? Image.memory(_newBytes!, fit: BoxFit.contain)
                          : _imageUrl != null
                              ? CachedNetworkImage(imageUrl: _imageUrl!, fit: BoxFit.contain)
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined, size: 32, color: AppTheme.midGray),
                                    const SizedBox(height: 8),
                                    Text(_t('صورة الموديل', 'Model image'), style: const TextStyle(color: AppTheme.midGray)),
                                  ],
                                ),
                    ),
                  ),
                ),
              ),
              if (_newBytes != null || _imageUrl != null)
                Center(
                  child: TextButton(onPressed: _pickImage, child: Text(_t('تغيير الصورة', 'Change image'))),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _t('اسم الموديل', 'Model name'),
                  hintText: 'iPhone 13 Pro',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_t('ظاهر للزبائن', 'Visible to customers')),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 12),

              // المساحات
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sd_storage_outlined, size: 20, color: AppTheme.gold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t(
                          'متنساش المساحات! الزبون بيختار المساحة وهو بيبيع، وكل مساحة ليها سعرها الأساسي (مستعمل بأحسن حالة).',
                          "Don't forget the storage options! The customer picks the storage when selling, and each one has its own base price (used, best condition).",
                        ),
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(_t('المساحات والأسعار', 'Storage options & prices'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _suggestions) ActionChip(label: Text('+ $s'), onPressed: () => _addSuggestion(s)),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _rows[i].storage,
                          decoration: InputDecoration(labelText: _t('المساحة', 'Storage'), hintText: '128GB'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: TextField(
                          controller: _rows[i].price,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(labelText: _t('السعر الأساسي', 'Base price'), suffixText: _t('ج.م', 'EGP')),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _rows.length == 1
                            ? null
                            : () => setState(() {
                                  _rows.removeAt(i).dispose();
                                }),
                      ),
                    ],
                  ),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => setState(() => _rows.add(_StorageRow())),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(_t('مساحة تانية', 'Add another storage')),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_t('حفظ', 'Save')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
