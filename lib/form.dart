import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trip_logger/utils/utils.dart';
// import './services/model.dart';
import 'utils/helperdb.dart';

class AddTripForm extends StatefulWidget {
  /// Callback when form is submitted, providing the collected data as a Map.
  // final void Function(Map<String, dynamic>) onSubmit;
  final String? busno;
  AddTripForm({super.key, this.busno});

  @override
  _AddTripFormState createState() => _AddTripFormState();
}

class _AddTripFormState extends State<AddTripForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _busNumberController = TextEditingController();
  final TextEditingController _routeNameController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteBodyController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  List<XFile> _videos = [];

   @override
  void initState() {
    super.initState();
     log("${widget.busno}");
    if (widget.busno != null) {
      _busNumberController.text = widget.busno!;
    } 
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _routeNameController.dispose();
    _sourceController.dispose();
    _destinationController.dispose();
    _noteTitleController.dispose();
    _noteBodyController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;
    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _showMediaOptions() async {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? photo = await _picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (photo != null) setState(() => _images.add(photo));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Select Photos from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final List<XFile>? photos = await _picker.pickMultiImage();
                    if (photos != null) setState(() => _images.addAll(photos));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam),
                  title: const Text('Select Video from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    final XFile? video = await _picker.pickVideo(
                      source: ImageSource.gallery,
                    );
                    if (video != null) setState(() => _videos.add(video));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // ignore: unused_local_variable
        final result = await insertTripWithFields(
          busNumber: _busNumberController.text.trim(),
          source: _sourceController.text.trim(),
          routeName: _routeNameController.text.trim(),
          destination: _destinationController.text.trim(),
          dateTime: _selectedDateTime,
          noteTitle: _noteTitleController.text.trim(),
          noteBody: _noteBodyController.text.trim(),
          photos: _images.map((img) => img.path).toList().toString(),
          videos: _videos.map((vid) => vid.path).toList().toString(),
        );

        var busno = _busNumberController.text.trim();
        
          Navigator.pop(context, busno);

        showSuccessBox(context, "Successfully added ");
      } catch (e) {
        dialogBox(context, "Failed", Colors.red, "$e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _busNumberController,
                decoration: const InputDecoration(
                  labelText: 'Bus Number',
                  hintText: 'e.g. KA57F1234',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _routeNameController,
                decoration: const InputDecoration(
                  labelText: 'Route Name',
                  hintText: 'e.g. 282M',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sourceController,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                        hintText: 'e.g. Station A',
                      ),
                      // validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.arrow_forward),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _destinationController,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                        hintText: 'e.g. Station B',
                      ),
                      // validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date & Time'),
                subtitle: Text(
                  '${_selectedDateTime.toLocal()}'.split('.').first,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDateTime,
                ),
              ),
              const Divider(),
              TextFormField(
                controller: _noteTitleController,
                decoration: const InputDecoration(labelText: 'Note Title'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteBodyController,
                decoration: const InputDecoration(labelText: 'Note Body'),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showMediaOptions,
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Media'),
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Image.file(
                          File(_images[index].path),
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (_videos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      _videos.map((video) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            'Video: ${video.name}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _handleSubmit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
