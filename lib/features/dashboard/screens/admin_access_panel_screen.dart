import 'package:flutter/material.dart';
import 'package:lms/core/services/course_access_service.dart';
import 'package:lms/core/services/lecture_service.dart';
import 'package:lms/core/services/package_service.dart';
import 'package:lms/core/models/lecture_model.dart';
import 'package:lms/core/models/package_model.dart';

class AdminAccessPanelScreen extends StatefulWidget {
  const AdminAccessPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminAccessPanelScreenState createState() => _AdminAccessPanelScreenState();
}

class _AdminAccessPanelScreenState extends State<AdminAccessPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final CourseAccessService _accessService = CourseAccessService();
  final LectureService _lectureService = LectureService();
  final PackageService _packageService = PackageService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(
    text: '0',
  );

  String _itemType = 'lecture'; // 'lecture' or 'package'
  String? _selectedItemId;

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _grantAccess() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an item')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _accessService.grantManualAccess(
        userEmail: _emailController.text.trim(),
        itemId: _selectedItemId!,
        itemType: _itemType,
        accessDurationDays: int.tryParse(_durationController.text) ?? 0,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access granted successfully')),
      );
      _emailController.clear();
      setState(() {
        _selectedItemId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Access Panel')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Grant Access Manually',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'User Email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return 'Enter user email';
                        if (!val.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _itemType,
                      decoration: const InputDecoration(labelText: 'Item Type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'lecture',
                          child: Text('Single Course'),
                        ),
                        DropdownMenuItem(
                          value: 'package',
                          child: Text('Package (Bundle)'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _itemType = val!;
                          _selectedItemId =
                              null; // reset selection when type changes
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    if (_itemType == 'lecture')
                      StreamBuilder<List<LectureModel>>(
                        stream: _lectureService.getAllLecturesStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const CircularProgressIndicator();
                          final items = snapshot.data!;
                          return DropdownButtonFormField<String>(
                            value: _selectedItemId,
                            decoration: const InputDecoration(
                              labelText: 'Select Course',
                            ),
                            isExpanded: true,
                            items: items.map((l) {
                              return DropdownMenuItem(
                                value: l.id,
                                child: Text('${l.title} (\$${l.price})'),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedItemId = val),
                          );
                        },
                      )
                    else
                      StreamBuilder<List<PackageModel>>(
                        stream: _packageService.getAllPackagesStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const CircularProgressIndicator();
                          final items = snapshot.data!;
                          return DropdownButtonFormField<String>(
                            value: _selectedItemId,
                            decoration: const InputDecoration(
                              labelText: 'Select Package',
                            ),
                            isExpanded: true,
                            items: items.map((p) {
                              return DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.title} (\$${p.price})'),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedItemId = val),
                          );
                        },
                      ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Access Duration (Days, 0 for lifetime)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) =>
                          val!.isEmpty ? 'Enter duration' : null,
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _grantAccess,
                      child: const Text(
                        'Grant Access',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
