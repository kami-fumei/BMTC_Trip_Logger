class Trip {
  final int? id;
  final String busNumber;
  final String? routeName; 
  final String dateTime;
  final String? source;
  final String? destination;
  final String? noteTitle;
  final String? noteBody;
  final List<String>? photos;
  final List<String>? videos;

  Trip({
    this.id,
    required this.busNumber,
    required this.routeName,
    required this.dateTime,
    this.source,
    this.destination,
    this.noteTitle,
    this.noteBody,
    this.photos,
    this.videos,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bus_number': busNumber,
      'route_name': routeName,
      'source': source,
      'destination': destination,
      'date_time': dateTime,
      'note_title': noteTitle,
      'note_body': noteBody,
      'photos':photos?.join(',') ,
      'videos':videos?.join(',') ,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'],
      busNumber: map['bus_number'],
      routeName: map['route_name'],
      source: map['source'],
      destination: map['destination'],
      dateTime: map['date_time'],
      noteTitle: map['note_title'],
      noteBody: map['note_body'],
      photos: map['photos']?.toString().split(','),
      videos: map['videos']?.toString().split(','),
    );
  }
}
