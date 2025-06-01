import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trip_logger/utils/utils.dart';
import 'utils/helperdb.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class AddTripForm extends StatefulWidget {
  final String? busno;
  AddTripForm({super.key, this.busno});

  @override
  _AddTripFormState createState() => _AddTripFormState();
}

class _AddTripFormState extends State<AddTripForm> {
  final _formKey = GlobalKey<FormState>();

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
      builder: (context) => SafeArea(
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
        await insertTripWithFields(
          busNumber: _busNumberController.text.trim(),
          source: _sourceController.text.trim(),
          routeName: _routeNameController.text.trim(),
          destination: _destinationController.text.trim(),
          dateTime: _selectedDateTime,
          noteTitle: _noteTitleController.text.trim(),
          noteBody: _noteBodyController.text.trim(),
          photos: _images.map((img) => img.path).toList(),
          videos: _videos.map((vid) => vid.path).toList(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bus Number
              TextFormField(
                controller: _busNumberController,
                decoration: InputDecoration(
                  labelText: 'Bus Number',
                  hintText: 'e.g. KA57F1234',
                  prefixIcon: Icon(Icons.directions_bus),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              // Route Name
              TextFormField(
                controller: _routeNameController,
                decoration: InputDecoration(
                  labelText: 'Route Name',
                  hintText: 'e.g. 282M',
                  prefixIcon: Icon(Icons.alt_route),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              // Source and Destination
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sourceController,
                      decoration: InputDecoration(
                        labelText: 'Source',
                        hintText: 'e.g. Station A',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.arrow_forward),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Destination',
                        hintText: 'e.g. Station B',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Date & Time
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date & Time'),
                subtitle: Text(
                  '${_selectedDateTime.toLocal()}'.split('.').first,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDateTime,
                ),
              ),
              const Divider(height: 28),
              // Note Title
              TextFormField(
                controller: _noteTitleController,
                decoration: InputDecoration(
                  labelText: 'Note Title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Note Body
              TextFormField(
                controller: _noteBodyController,
                decoration: InputDecoration(
                  labelText: 'Note Body',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              // Media Buttons
              OutlinedButton.icon(
                onPressed: _showMediaOptions,
                icon: const Icon(Icons.attach_file),
                label: const Text('Add Media'),
              ),
              // Show selected images
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_images[index].path),
                                width: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _images.removeAt(index);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              // Show selected videos
              if (_videos.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _videos.length,
                    itemBuilder: (context, index) {
                      final video = _videos[index];
                      return FutureBuilder<String?>(
                        future: VideoThumbnail.thumbnailFile(
                          video: video.path,
                          imageFormat: ImageFormat.PNG,
                          maxHeight: 90,
                          quality: 75,
                        ),
                        builder: (context, snapshot) {
                          Widget thumb;
                          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                            thumb = ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.file(
                                    File(snapshot.data!),
                                    width: 120,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _videos.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.close, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            thumb = Container(
                              width: 120,
                              height: 90,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: thumb,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: Icon(Icons.check),
                label: const Text('Submit'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
