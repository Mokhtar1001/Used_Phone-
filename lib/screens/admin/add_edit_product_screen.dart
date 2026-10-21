import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../providers/locale_provider.dart';
import '../../core/responsive.dart';
import '../../widgets/desktop_top_nav.dart';
import '../../widgets/profile_menu_button.dart';
import '../../widgets/overview_editor.dart';

/// يخزن الملف المختار مع الـ bytes بتاعته مع بعض - عشان نقرأ الملف مرة واحدة بس
/// ونستخدمه في المعاينة (Image.memory) والرفع، بطريقة شغالة على كل المنصات (موبايل وويب)
class _PickedImage {
  final XFile file;
  final Uint8List bytes;
  _PickedImage(this.file, this.bytes);
}

class AddEditProductScreen extends StatefulWidget {
  final String? productId;
  const AddEditProductScreen({super.key, this.productId});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProductService();

  final _nameEnController = TextEditingController();
  final _descEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _storageController = TextEditingController();
  final _colorController = TextEditingController();
  final _warrantyController = TextEditingController(text: '3');
  final _batteryController = TextEditingController();
  final _ramController = TextEditingController();
  final _overviewController = OverviewEditorController();

  String? _categoryId;
  String _condition = 'good';
  List<ProductCategory> _categories = [];
  List<String> _existingImages = [];
  // صور قديمة الأدمن شالها - بتتمسح فعليًا لما يدوس حفظ
  final List<String> _removedImages = [];
  final List<_PickedImage> _newImages = [];
  bool _isSaving = false;
  bool get _isEditing => widget.productId != null;

  /// هل المنتج آيفون؟ (من القسم أو الماركة أو الاسم) - لو آيفون بنطلب نسبة البطارية
  bool get _isIphone {
    bool hit(String t) {
      final v = t.toLowerCase();
      return v.contains('iphone') || v.contains('apple') || v.contains('ايفون') || v.contains('آيفون') || v.contains('ابل') || v.contains('أبل');
    }

    for (final c in _categories) {
      if (c.id == _categoryId && (hit(c.name(false)) || hit(c.name(true)))) return true;
    }
    return hit(_brandController.text) || hit(_nameEnController.text);
  }

  /// هل المنتج سامسونج؟ (من القسم أو الماركة أو الاسم) - لو سامسونج بنطلب الرام
  bool get _isSamsung {
    bool hit(String t) {
      final v = t.toLowerCase();
      return v.contains('samsung') || v.contains('galaxy') || v.contains('سامسونج') || v.contains('سامسونغ') || v.contains('جالاكسي') || v.contains('جلاكسي');
    }

    for (final c in _categories) {
      if (c.id == _categoryId && (hit(c.name(false)) || hit(c.name(true)))) return true;
    }
    return hit(_brandController.text) || hit(_nameEnController.text);
  }

  @override
  void initState() {
    super.initState();
    _brandController.addListener(_refresh);
    _nameEnController.addListener(_refresh);
    _loadCategories();
    if (_isEditing) _loadProduct();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _brandController.removeListener(_refresh);
    _nameEnController.removeListener(_refresh);
    _nameEnController.dispose();
    _descEnController.dispose();
    _priceController.dispose();
    _brandController.dispose();
    _storageController.dispose();
    _colorController.dispose();
    _warrantyController.dispose();
    _batteryController.dispose();
    _ramController.dispose();
    _overviewController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _service.getCategories();
    setState(() => _categories = categories);
  }

  Future<void> _loadProduct() async {
    final product = await _service.getProductById(widget.productId!);
    setState(() {
      _nameEnController.text = product.nameEn;
      _descEnController.text = product.descriptionEn ?? '';
      _priceController.text = product.price.toString();
      _brandController.text = product.brand ?? '';
      _storageController.text = product.storage ?? '';
      _colorController.text = product.color ?? '';
      _categoryId = product.categoryId;
      _condition = product.condition ?? 'good';
      _warrantyController.text = product.warrantyMonths.toString();
      _existingImages = List<String>.from(product.images);
      _batteryController.text = product.batteryHealth?.toString() ?? '';
      _ramController.text = product.ramGb?.toString() ?? '';
      _overviewController.load(product.overview);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _newImages.add(_PickedImage(picked, bytes)));
    }
  }

  void _removeExistingImage(String url) {
    setState(() {
      _existingImages.remove(url);
      _removedImages.add(url);
    });
  }

  void _removeNewImage(_PickedImage img) {
    setState(() => _newImages.remove(img));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final isArabic = context.read<LocaleProvider>().isArabic;

    // لازم صورة واحدة على الأقل (جديدة أو موجودة من قبل لو بتعدل)
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'لازم تضيف صورة واحدة على الأقل' : 'Please add at least one image')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'السعر لازم يكون أكبر من صفر' : 'Price must be greater than zero')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final product = Product(
      id: '',
      categoryId: _categoryId,
      // الأدمن بيدخل إنجليزي بس - بنكرره في الحقول العربي عشان الداتابيز/الشاشات القديمة تفضل شغالة
      nameAr: _nameEnController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      descriptionAr: _descEnController.text.trim(),
      descriptionEn: _descEnController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0,
      condition: _condition,
      brand: _brandController.text.trim(),
      storage: _storageController.text.trim(),
      color: _colorController.text.trim(),
      status: 'available',
      createdAt: DateTime.now(),
      warrantyMonths: int.tryParse(_warrantyController.text.trim()) ?? 3,
      batteryHealth: _isIphone ? int.tryParse(_batteryController.text.trim()) : null,
      ramGb: _isSamsung ? int.tryParse(_ramController.text.trim()) : null,
      overview: _overviewController.build(),
    );

    try {
      String productId;
      if (_isEditing) {
        productId = widget.productId!;
        await _service.updateProduct(productId, product);
      } else {
        productId = await _service.createProduct(product);
      }

      for (final url in _removedImages) {
        await _service.deleteProductImageByUrl(productId, url);
      }

      for (final image in _newImages) {
        await _service.uploadProductImage(productId, image.file);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'حصل خطأ أثناء الحفظ: $e' : 'Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    final title = _isEditing ? (isArabic ? 'تعديل منتج' : 'Edit Product') : (isArabic ? 'إضافة منتج' : 'Add Product');
    final isDesktop = Responsive.isDesktop(context);

    // نافيجيشن علوي على الديسكتوب/الويب (زي باقي الصفحات)، وAppBar عادي على الموبايل
    final PreferredSizeWidget appBar = isDesktop
        ? DesktopTopNav(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            items: const [],
            trailing: const Row(mainAxisSize: MainAxisSize.min, children: [ProfileMenuButton()]),
          )
        : AppBar(title: Text(title));

    return Scaffold(
      appBar: appBar,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isDesktop)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back)),
                          const SizedBox(width: 8),
                          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  // الصور
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._existingImages.map((url) => _imageTile(
                              image: CachedNetworkImage(imageUrl: url, width: 100, height: 100, fit: BoxFit.cover),
                              onRemove: () => _removeExistingImage(url),
                              isArabic: isArabic,
                            )),
                        ..._newImages.map((img) => _imageTile(
                              image: Image.memory(img.bytes, width: 100, height: 100, fit: BoxFit.cover),
                              onRemove: () => _removeNewImage(img),
                              isArabic: isArabic,
                            )),
                        InkWell(
                          onTap: _pickImage,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_a_photo_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameEnController,
                    decoration: InputDecoration(labelText: isArabic ? 'اسم المنتج' : 'Product Name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? (isArabic ? 'مطلوب' : 'Required') : null,
                  ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: isArabic ? 'السعر' : 'Price'),
                validator: (v) {
                  final parsed = double.tryParse(v ?? '');
                  if (parsed == null) return isArabic ? 'سعر غير صحيح' : 'Invalid price';
                  if (parsed <= 0) return isArabic ? 'السعر لازم يكون أكبر من صفر' : 'Price must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: InputDecoration(labelText: isArabic ? 'اختر القسم' : 'Select Category'),
                items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name(isArabic)))).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: InputDecoration(labelText: isArabic ? 'الحالة' : 'Condition'),
                items: [
                  DropdownMenuItem(value: 'excellent', child: Text(isArabic ? 'ممتازة' : 'Excellent')),
                  DropdownMenuItem(value: 'good', child: Text(isArabic ? 'جيدة' : 'Good')),
                  DropdownMenuItem(value: 'fair', child: Text(isArabic ? 'مقبولة' : 'Fair')),
                ],
                onChanged: (v) => setState(() => _condition = v!),
              ),
              const SizedBox(height: 12),
              // الضمان تحت الجريد: بالشهور (الافتراضي 3 شهور)
              TextFormField(
                controller: _warrantyController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                decoration: InputDecoration(
                  labelText: isArabic ? 'الضمان (بالشهور)' : 'Warranty (months)',
                  suffixText: isArabic ? 'شهور' : 'months',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _brandController, decoration: InputDecoration(labelText: isArabic ? 'الماركة' : 'Brand'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _storageController, decoration: InputDecoration(labelText: isArabic ? 'المساحة' : 'Storage'))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _colorController, decoration: InputDecoration(labelText: isArabic ? 'اللون' : 'Color')),
              // اختبار إضافي للآيفون: نسبة صحة البطارية
              if (_isIphone) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _batteryController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  decoration: InputDecoration(
                    labelText: isArabic ? 'نسبة البطارية (Battery Health)' : 'Battery Health',
                    suffixText: '%',
                    prefixIcon: const Icon(Icons.battery_charging_full_outlined),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return isArabic ? 'اكتب نسبة البطارية' : 'Enter battery health';
                    if (n < 1 || n > 100) return isArabic ? 'من 1 إلى 100' : 'Must be 1-100';
                    return null;
                  },
                ),
              ],
              // سامسونج: الرام بالجيجا
              if (_isSamsung) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ramController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                  decoration: InputDecoration(
                    labelText: isArabic ? 'الرام (RAM)' : 'RAM',
                    suffixText: 'GB',
                    prefixIcon: const Icon(Icons.memory),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return isArabic ? 'اكتب حجم الرام' : 'Enter RAM size';
                    if (n < 1 || n > 64) return isArabic ? 'من 1 إلى 64' : 'Must be 1-64';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _descEnController,
                maxLines: 3,
                decoration: InputDecoration(labelText: isArabic ? 'الوصف' : 'Description'),
              ),
              const SizedBox(height: 12),
              // الـ Overview: بيظهر في صفحة المنتج على الجنب (مش ثابت، كل منتج بتكتبله بتاعه)
              Card(
                margin: EdgeInsets.zero,
                child: ExpansionTile(
                  maintainState: true,
                  leading: const Icon(Icons.article_outlined),
                  title: Text(isArabic ? 'Overview (نظرة عامة)' : 'Overview'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [OverviewEditor(controller: _overviewController, isArabic: isArabic)],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isArabic ? 'حفظ' : 'Save'),
              ),
            ],
            ),
          ),
        ),
      ),
    ),
  );
  }

  /// صورة مصغّرة بزرار X صغير لحذفها
  Widget _imageTile({required Widget image, required VoidCallback onRemove, required bool isArabic}) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Stack(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
          PositionedDirectional(
            top: 4,
            end: 4,
            child: Tooltip(
              message: isArabic ? 'حذف الصورة' : 'Remove image',
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
