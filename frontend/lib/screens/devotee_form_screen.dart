import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class DevoteeFormScreen extends StatefulWidget {
  final Devotee? devotee;
  const DevoteeFormScreen({super.key, this.devotee});

  @override
  State<DevoteeFormScreen> createState() => _DevoteeFormScreenState();
}

class _DevoteeFormScreenState extends State<DevoteeFormScreen> {
  late TextEditingController _nameController;
  late TextEditingController _fatherController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _villageController;
  late TextEditingController _familyIdController;
  bool _saving = false;

  bool get _isEdit => widget.devotee != null;

  @override
  void initState() {
    super.initState();
    final d = widget.devotee;
    _nameController = TextEditingController(text: d?.devoteeName ?? '');
    _fatherController = TextEditingController(text: d?.fatherName ?? '');
    _mobileController = TextEditingController(text: d?.mobile ?? '');
    _addressController = TextEditingController(text: d?.address ?? '');
    _villageController = TextEditingController(text: d?.village ?? '');
    _familyIdController = TextEditingController(text: d?.familyId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _villageController.dispose();
    _familyIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('பெயர் தேவை / Name is required'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _saving = true);
    final devotee = Devotee(
      devoteeId: widget.devotee?.devoteeId ?? 0,
      devoteeName: _nameController.text.trim(),
      fatherName: _fatherController.text.trim().isEmpty ? null : _fatherController.text.trim(),
      mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      village: _villageController.text.trim().isEmpty ? null : _villageController.text.trim(),
      familyId: _familyIdController.text.trim().isEmpty ? null : _familyIdController.text.trim(),
    );

    try {
      if (_isEdit) {
        await ApiService.updateDevotee(widget.devotee!.devoteeId, devotee);
      } else {
        await ApiService.createDevotee(devotee);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'பக்தரைத் திருத்து' : 'புதிய பக்தர் சேர்க்க')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(_nameController, 'பக்தர் பெயர் / Devotee Name *', Icons.person),
              const SizedBox(height: 14),
              _field(_fatherController, 'தந்தை பெயர் / Father Name', Icons.family_restroom),
              const SizedBox(height: 14),
              _field(_mobileController, 'கைபேசி எண் / Mobile', Icons.phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              _field(_villageController, 'ஊர் / Village', Icons.location_city),
              const SizedBox(height: 14),
              _field(_familyIdController, 'குடும்ப ஐடி / Family ID', Icons.groups),
              const SizedBox(height: 14),
              _field(_addressController, 'முகவரி / Address', Icons.home, maxLines: 3),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isEdit ? 'புதுப்பிக்கவும் / Update' : 'சேமிக்கவும் / Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}