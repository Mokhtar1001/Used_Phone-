import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../providers/locale_provider.dart';

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

  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descArController = TextEditingController();
  final _descEnController = TextEditingController();
  final _priceController = TextEditingController();
  final _brandController = TextEditingController();
  final _storageController = TextEditingController();
  final _colorController = TextEditingController();

  String? _categoryId;
  String _condition = 'good';
  List<ProductCategory> _categories = [];
  List<String> _existingImages = [];
  final List<_PickedImage> _newImages = [];
  bool _isSaving = false;
  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditing) _loadProduct();
  }

  Future<void> _loadCategories() async {
    final categories = await _service.getCategories();
    setState(() => _categories = categories);
  }

  Future<void> _loadProduct() async {
    final product = await _service.getProductById(widget.productId!);
    setState(() {
      _nameArController.text = product.nameAr;
      _nameEnController.text = product.nameEn;
      _descArController.text = product.descriptionAr ?? '';
      _descEnController.text = product.descriptionEn ?? '';
      _priceController.text = product.price.toString();
      _brandController.text = product.brand ?? '';
      _storageController.text = product.storage ?? '';
      _colorController.text = product.color ?? '';
      _categoryId = product.categoryId;
      _condition = product.condition ?? 'good';
      _existingImages = product.images;
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
      nameAr: _nameArController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      descriptionAr: _descArController.text.trim(),
      descriptionEn: _descEnController.text.trim(),
      price: double.tryParse(_priceController.text) ?? 0,
      condition: _condition,
      brand: _brandController.text.trim(),
      storage: _storageController.text.trim(),
      color: _colorController.text.trim(),
      status: 'available',
      createdAt: DateTime.now(),
    );

    String productId;
    if (_isEditing) {
      productId = widget.productId!;
      await _service.updateProduct(productId, product);
    } else {
      productId = await _service.createProduct(product);
    }

    for (final image in _newImages) {
      await _service.uploadProductImage(productId, image.file);
    }

    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? (isArabic ? 'تعديل منتج' : 'Edit Product') : (isArabic ? 'إضافة منتج' : 'Add Product'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الصور
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._existingImages.map((url) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(imageUrl: url, width: 100, height: 100, fit: BoxFit.cover),
                          ),
                        )),
                    ..._newImages.map((img) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(img.bytes, width: 100, height: 100, fit: BoxFit.cover),
                          ),
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
                controller: _nameArController,
                decoration: InputDecoration(labelText: isArabic ? 'اسم المنتج (عربي)' : 'Product Name (Arabic)'),
                validator: (v) => (v == null || v.isEmpty) ? (isArabic ? 'مطلوب' : 'Required') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(labelText: isArabic ? 'اسم المنتج (إنجليزي)' : 'Product Name (English)'),
                validator: (v) => (v == null || v.isEmpty) ? (isArabic ? 'مطلوب' : 'Required') : null,
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
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _brandController, decoration: InputDecoration(labelText: isArabic ? 'الماركة' : 'Brand'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(controller: _storageController, decoration: InputDecoration(labelText: isArabic ? 'المساحة' : 'Storage'))),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _colorController, decoration: InputDecoration(labelText: isArabic ? 'اللون' : 'Color')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descArController,
                maxLines: 3,
                decoration: InputDecoration(labelText: isArabic ? 'الوصف (عربي)' : 'Description (Arabic)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descEnController,
                maxLines: 3,
                decoration: InputDecoration(labelText: isArabic ? 'الوصف (إنجليزي)' : 'Description (English)'),
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
    );
  }
}