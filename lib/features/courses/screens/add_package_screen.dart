import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lms/core/models/package_model.dart';
import 'package:lms/core/models/lecture_model.dart';
import 'package:lms/core/services/package_service.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/services/file_upload_service.dart';

class AddPackageScreen extends StatefulWidget {
  final PackageModel? existingPackage;

  const AddPackageScreen({Key? key, this.existingPackage}) : super(key: key);

  @override
  _AddPackageScreenState createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final PackageService _packageService = PackageService();
  final LectureService _lectureService = LectureService();
  final FileUploadService _fileUploadService = FileUploadService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  List<String> _selectedLectureIds = [];
  String _visibility = 'private'; // 'published', 'private'

  File? _thumbnailFile;
  String? _thumbnailUrl;
  bool _isLoading = false;
  bool _isLifetime = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingPackage != null) {
      final p = widget.existingPackage!;
      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _priceController.text = p.price.toString();
      _isLifetime = p.isLifetime;
      _durationController.text = p.accessDurationDays.toString();
      _selectedLectureIds = List.from(p.includedLectureIds);
      _visibility = p.visibility;
      _thumbnailUrl = p.thumbnailUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _fileUploadService.pickImage();
    if (file != null) {
      setState(() {
        _thumbnailFile = file;
      });
    }
  }

  Future<void> _savePackage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_thumbnailFile == null && _thumbnailUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a thumbnail')),
      );
      return;
    }
    if (_selectedLectureIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one course for this package'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String finalThumbnailUrl = _thumbnailUrl ?? '';
      if (_thumbnailFile != null) {
        final url = await _fileUploadService.uploadFile(
          _thumbnailFile!,
          folderType: 'thumbnails',
        );
        if (url != null) {
          finalThumbnailUrl = url;
        } else {
          throw Exception('Failed to upload thumbnail');
        }
      }

      final packageId =
          widget.existingPackage?.id ??
          FirebaseFirestore.instance.collection('packages').doc().id;

      final package = PackageModel(
        id: packageId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        thumbnailUrl: finalThumbnailUrl,
        price: double.tryParse(_priceController.text) ?? 0.0,
        isLifetime: _isLifetime,
        accessDurationDays: !_isLifetime
            ? (int.tryParse(_durationController.text) ?? 0)
            : 0,
        includedLectureIds: _selectedLectureIds,
        visibility: _visibility,
        createdAt: widget.existingPackage?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.existingPackage == null) {
        await _packageService.createPackage(package);
      } else {
        await _packageService.updatePackage(package);
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving package: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingPackage == null ? 'Add Package' : 'Edit Package',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Thumbnail Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: _thumbnailFile != null
                            ? Image.file(_thumbnailFile!, fit: BoxFit.cover)
                            : _thumbnailUrl != null
                            ? Image.network(_thumbnailUrl!, fit: BoxFit.cover)
                            : const Center(
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Package Title',
                      ),
                      validator: (val) => val!.isEmpty ? 'Enter a title' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 3,
                      validator: (val) =>
                          val!.isEmpty ? 'Enter a description' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) => val!.isEmpty ? 'Enter a price' : null,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Lifetime Access',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: const Text(
                          'Students keep this bundle forever',
                          style: TextStyle(color: Colors.white70),
                        ),
                        value: _isLifetime,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (val) {
                          setState(() => _isLifetime = val);
                        },
                      ),
                    ),
                    if (!_isLifetime) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Access Duration (Days)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) =>
                            val!.isEmpty ? 'Enter duration in days' : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _visibility,
                      decoration: const InputDecoration(
                        labelText: 'Visibility',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Published'),
                        ),
                        DropdownMenuItem(
                          value: 'private',
                          child: Text('Private'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _visibility = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Multi-select for lectures
                    const Text(
                      'Include Courses:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<LectureModel>>(
                      // Only let them bundle published/scheduled lectures, or all.
                      // Depending on requirements we show all lectures so they can bundle private ones too.
                      stream: _lectureService.getAllLecturesStream(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const CircularProgressIndicator();
                        final lectures = snapshot.data!;
                        if (lectures.isEmpty)
                          return const Text('No courses available.');
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: lectures.length,
                          itemBuilder: (context, index) {
                            final l = lectures[index];
                            final isSelected = _selectedLectureIds.contains(
                              l.id,
                            );
                            return CheckboxListTile(
                              title: Text(l.title),
                              subtitle: Text(
                                '${l.categoryName} - \$${l.price}',
                              ),
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedLectureIds.add(l.id);
                                  } else {
                                    _selectedLectureIds.remove(l.id);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _savePackage,
                      child: const Text(
                        'Save Package',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
