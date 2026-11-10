import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../models/incident.dart';
import '../../providers/auth_provider.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/category_tile.dart';
import '../../widgets/state_views.dart';

/// Used for both creating a new report and editing an existing one
/// (students, while the report is still "submitted").
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.existing});
  final Incident? existing;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late String _category;
  String? _location;
  File? _photo;
  bool _removeExistingPhoto = false;
  bool _categoryError = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _category = e?.category ?? '';
    _location = e?.location;
    if (e != null && !campusLocations.contains(e.location)) _location = 'Other';
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await ImagePicker()
          .pickImage(source: source, maxWidth: 1280, imageQuality: 75);
      if (x != null) {
        setState(() {
          _photo = File(x.path);
          _removeExistingPhoto = false;
        });
      }
    } catch (_) {
      if (mounted) showSnack(context, 'Could not access the camera/gallery', error: true);
    }
  }

  void _photoSheet() => showModalBottomSheet(
        context: context,
        builder: (_) => SafeArea(
          child: Wrap(children: [
            ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.camera);
                }),
            ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.gallery);
                }),
          ]),
        ),
      );

  Future<void> _submit() async {
    setState(() => _categoryError = _category.isEmpty);
    if (!_form.currentState!.validate() || _category.isEmpty) return;
    final auth = context.read<AuthProvider>();
    final inc = context.read<IncidentProvider>();
    final nav = Navigator.of(context);
    try {
      if (_editing) {
        await inc.edit(
          widget.existing!.copyWith(
              title: _title.text.trim(),
              description: _desc.text.trim(),
              category: _category,
              location: _location),
          newPhoto: _photo,
          removePhoto: _removeExistingPhoto && _photo == null,
        );
      } else {
        await inc.submit(
          uid: auth.user!.uid,
          reporterName: auth.displayName,
          title: _title.text,
          description: _desc.text,
          category: _category,
          location: _location!,
          photo: _photo,
        );
      }
      if (!mounted) return;
      showSnack(context, _editing ? 'Report updated' : 'Report submitted');
      nav.pop();
    } catch (e) {
      debugPrint('Save report failed: $e');
      if (mounted) {
        final msg = e.toString().contains('Photo upload failed')
            ? 'Photo upload failed. Check your Cloudinary settings.'
            : 'Could not save the report. Please try again.';
        showSnack(context, msg, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = context.watch<IncidentProvider>().saving;
    final existingUrl =
        _removeExistingPhoto ? null : widget.existing?.photoUrl;
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit Report' : 'Report an Incident')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Select a category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final c in incidentCategories)
                CategoryTile(
                  category: c,
                  selected: _category == c.key,
                  onTap: () => setState(() {
                    _category = c.key;
                    _categoryError = false;
                  }),
                ),
            ]),
            if (_categoryError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Please select a category',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              maxLength: 80,
              decoration: const InputDecoration(
                  labelText: 'Title', hintText: 'Briefly describe the issue…'),
              validator: Validators.title,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _desc,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What happened, when, impact, etc.',
                  alignLabelWithHint: true),
              validator: Validators.description,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _location,
              decoration: const InputDecoration(
                  labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined)),
              items: [
                for (final l in campusLocations) DropdownMenuItem(value: l, child: Text(l))
              ],
              onChanged: (v) => setState(() => _location = v),
              validator: (v) => v == null ? 'Select a location' : null,
            ),
            const SizedBox(height: 16),
            const Text('Add a photo (optional)',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _photoBox(existingUrl),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: saving ? null : _submit,
              child: saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_editing ? 'Save changes' : 'Submit Report'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _photoBox(String? existingUrl) {
    final hasImage = _photo != null || existingUrl != null;
    if (!hasImage) {
      return InkWell(
        onTap: _photoSheet,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 110,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
              color: Colors.white),
          child: const Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_photo_alternate_outlined),
            SizedBox(height: 4),
            Text('Tap to add photo'),
          ]),
        ),
      );
    }
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: _photo != null
              ? Image.file(_photo!, fit: BoxFit.cover)
              : CachedNetworkImage(imageUrl: existingUrl!, fit: BoxFit.cover),
        ),
      ),
      Positioned(
        right: 8,
        top: 8,
        child: CircleAvatar(
          backgroundColor: Colors.black54,
          child: IconButton(
            tooltip: 'Remove photo',
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() {
              _photo = null;
              _removeExistingPhoto = true;
            }),
          ),
        ),
      ),
    ]);
  }
}
