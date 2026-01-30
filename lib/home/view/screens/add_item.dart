import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uborrow/core/repository/cloudinary_provider.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final hostelCtrl = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  final ImagePicker _picker = ImagePicker();

  int? _imageWidth;
  int? _imageHeight;
  double? _imageSizeInKB;
  String? _selectedSizeLabel;

  // Categories for items
  final List<String> _categories = [
    'Electronics',
    'Books',
    'Sports Equipment',
    'Musical Instruments',
    'Tools',
    'Kitchen Items',
    'Other',
  ];
  String? _selectedCategory;

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    hostelCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateImagePreview(File file, {required String label}) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) return;

    setState(() {
      _selectedImage = file;
      _imageWidth = decoded.width;
      _imageHeight = decoded.height;
      _imageSizeInKB = bytes.length / 1024;
      _selectedSizeLabel = label;
    });
  }

  Future<File> _resizeImage(
    File file, {
    required int maxSize,
    int quality = 85,
  }) async {
    final bytes = await file.readAsBytes();
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) return file;

    final resized = img.copyResize(
      originalImage,
      width: originalImage.width > originalImage.height ? maxSize : null,
      height: originalImage.height >= originalImage.width ? maxSize : null,
    );

    final tempDir = await getTemporaryDirectory();
    final resizedPath = path.join(
      tempDir.path,
      'resized_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final resizedFile = File(resizedPath)
      ..writeAsBytesSync(img.encodeJpg(resized, quality: quality));

    return resizedFile;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // keep original first
      );

      if (image != null) {
        final file = File(image.path);
        _showImageSizeDialog(file);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showSnackBar(
        'Could not access gallery. Please check permissions.',
        isError: true,
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image != null) {
        final file = File(image.path);
        _showImageSizeDialog(file);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      _showSnackBar(
        'Could not access camera. Please check permissions.',
        isError: true,
      );
    }
  }

  Future<void> _showImageSizeDialog(File imageFile) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Select Image Size',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _sizeTile(
              label: 'Original (Best quality)',
              onTap: () async {
                Navigator.pop(context);
                await _updateImagePreview(imageFile, label: 'Original');
              },
            ),

            _sizeTile(
              label: 'Medium (1024px)',
              onTap: () async {
                Navigator.pop(context);
                final resized = await _resizeImage(imageFile, maxSize: 1024);
                await _updateImagePreview(resized, label: 'Medium (1024px)');
              },
            ),

            _sizeTile(
              label: 'Small (720px)',
              onTap: () async {
                Navigator.pop(context);
                final resized = await _resizeImage(imageFile, maxSize: 720);
                await _updateImagePreview(resized, label: 'Small (720px)');
              },
            ),

            _sizeTile(
              label: 'Thumbnail (480px)',
              onTap: () async {
                Navigator.pop(context);
                final resized = await _resizeImage(imageFile, maxSize: 480);
                await _updateImagePreview(resized, label: 'Thumbnail (480px)');
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _sizeTile({required String label, required VoidCallback onTap}) {
    return ListTile(
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.grey),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please sign in to add items', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
    });

    try {
      String? imageUrl;

      // Upload image to Cloudinary if selected
      if (_selectedImage != null) {
        try {
          final cloudinaryService = ref.read(cloudinaryServiceProvider);

          imageUrl = await cloudinaryService.uploadImage(
            imageFile: _selectedImage!,
            folder: 'uborrow_items',
            onProgress: (progress) {
              if (mounted) {
                setState(() {
                  _uploadProgress = progress;
                });
              }
            },
          );

          if (imageUrl == null) {
            throw Exception('Image upload returned null');
          }
        } catch (e) {
          debugPrint('Cloudinary upload error: $e');
          // Ask user if they want to continue without image
          final shouldContinue = await _showContinueDialog();
          if (!shouldContinue) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
          imageUrl = ''; // Continue without image
        }
      }

      // Add item to Firestore
      await FirebaseFirestore.instance.collection('items').add({
        'name': nameCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'hostel': hostelCtrl.text.trim(),
        'category': _selectedCategory ?? 'Other',
        'image': imageUrl ?? '',
        'ownerId': user.uid,
        'ownerEmail': user.email ?? '',
        'available': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSnackBar('Item added successfully!');

        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error adding item: $e');
      if (mounted) {
        _showSnackBar('Error adding item: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  Future<bool> _showContinueDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Upload Failed'),
        content: const Text(
          'Failed to upload image. Would you like to continue adding the item without an image?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 3),
        action: isError
            ? SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Item"), elevation: 0),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  if (_uploadProgress > 0)
                    Column(
                      children: [
                        Text(
                          _uploadProgress < 1.0
                              ? 'Uploading image... ${(_uploadProgress * 100).toStringAsFixed(0)}%'
                              : 'Saving item...',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Saving item...',
                      style: TextStyle(fontSize: 16),
                    ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image picker
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _selectedImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),

                                  // Edit button
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: _showImageSourceDialog,
                                      ),
                                    ),
                                  ),

                                  // Size & resolution badge
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_selectedSizeLabel ?? ''} • '
                                        '${_imageWidth}×${_imageHeight}px • '
                                        '${_imageSizeInKB!.toStringAsFixed(1)} KB',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 50,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to add image (optional)',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Item Name
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Item Name",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter item name';
                        }
                        if (value.trim().length < 3) {
                          return 'Item name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Hostel/Location
                    TextFormField(
                      controller: hostelCtrl,
                      decoration: const InputDecoration(
                        labelText: "Hostel/Location",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                        hintText: 'e.g., Hostel A, Building 3',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your hostel or location';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),

                    // Description
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                        hintText: 'Describe your item, its condition, etc.',
                      ),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 5) {
                          return 'Description must be at least 10 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 25),

                    // Add Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _addItem,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Add Item",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
