
 import 'package:flutter/material.dart';

Future<dynamic> dialogBox(
  BuildContext context,
  String aTitle,
  aColour,
  aMessage,
) {
  return showDialog(
    context: context,
    builder: (context) {
      return SimpleDialog(
        title: Text(aTitle, style: TextStyle(color: aColour)),
        contentPadding: EdgeInsets.all(20),
        children: [Text(aMessage)],
      );
    },
  );
}

void showSuccessBox(BuildContext context, String msg) {
  final snackBar = SnackBar(
    content: Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green),
        SizedBox(width: 10),
        Text('Successfully  $msg'),
      ],
    ),
    backgroundColor: Colors.black87,
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: 2),
    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}


 Future<bool> showDeleteBox(context) async{
final shouldDelete = await  showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Trip'),
      content: const Text('Are you sure you want to delete this trip?'),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 238, 114, 105)),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Delete',style:TextStyle(color: Colors.white) ,),
        ),
      ],
    ),
  );
  return shouldDelete!;
 }

 // lib/helpers/beautiful_travel_dialog.dart


/// Displays a custom, beautiful dialog showing previous travels for a bus.


// Future<void> showBeautifulTravelDialog2(

//   BuildContext context,
//   String busNumber,
//   List<Map<String, dynamic>> summary,
// ) {
//   return showGeneralDialog(
//     context: context,
//     barrierDismissible: true,
//     barrierLabel: 'Previous Travels',
//     transitionDuration: const Duration(milliseconds: 400),
//     pageBuilder: (context, anim1, anim2) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Material(
//             color: Colors.transparent,
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [const Color.fromARGB(255, 222, 226, 232), const Color.fromARGB(255, 148, 213, 243)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black26,
//                     blurRadius: 12,
//                     offset: Offset(0, 6),
//                   ),
//                 ],
//               ),
//               padding: const EdgeInsets.all(20),
//               child: IntrinsicWidth(
//                 stepWidth: MediaQuery.of(context).size.width * 0.7,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Header
//                     Row(
//                       children: [
//                         Icon(Icons.directions_bus, color: Colors.white, size: 28),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             'Bus: $busNumber',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () => Navigator.of(context).pop(),
//                           child: Icon(Icons.close, color: Colors.white),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     // Content
//                     if (summary.isEmpty)
//                       Text(
//                         'No previous travels found.',
//                         style: TextStyle(color: Colors.white70),
//                       )
//                     else
//                       ...summary.map((item) {
//                         final route = item['route_name'];
//                         final count = item['total_travels'];
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 4.0),
//                           child: Row(
//                             children: [
//                               Icon(Icons.place, color: Colors.white70, size: 18),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   '$route: $count times',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }).toList(),
//                     const SizedBox(height: 24),
//                     // Action Button
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color.fromARGB(255, 202, 180, 180),
//                         foregroundColor: const Color.fromARGB(255, 253, 253, 253),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       onPressed: () => Navigator.of(context).pop(),
//                       child: const Text('Close'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//     transitionBuilder: (context, anim1, anim2, child) {
//       return ScaleTransition(
//         scale: CurvedAnimation(
//           parent: anim1,
//           curve: Curves.easeOutBack,
//         ),
//         child: FadeTransition(
//           opacity: anim1,
//           child: child,
//         ),
//       );
//     },
//   );
// }

/// Shows a styled dialog notifying the user of their previous travels on a specific bus.
///
/// [context]: BuildContext to show the dialog.
/// [busNumber]: the bus number that was scanned.
/// [summary]: list of maps with keys 'route_name' and 'total_travels'.

/// 
Future<void> showAlreadyTraveledDialog(
  BuildContext context,
  String busNumber,
  List<Map<String, dynamic>> summary,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.directions_bus, size: 28, color: Color.fromARGB(255, 21, 146, 219)),
                SizedBox(width: 8),
                Text(
                  'Oh you have previously \n travelled!!!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 3, 87, 184),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bus Number
            Text(
              'Bus Number: $busNumber',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Travel summary list
            if (summary.isEmpty)
              const Text(
                'You have no previous travels on this bus.',
                style: TextStyle(fontSize: 16),
              )
            else
              ...summary.map((item) {
                final route = item['route_name'];
                final count = item['total_travels'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.place, size: 18, color: Color.fromARGB(255, 17, 111, 234)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$route: $count times',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            const SizedBox(height: 24),
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 7, 100, 222),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}