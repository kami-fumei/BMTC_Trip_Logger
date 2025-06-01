// ignore: unused_import
// import 'dart:developer';

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_logger/search_page.dart';
import 'package:trip_logger/specific_bus.dart';
import 'package:trip_logger/utils/utils.dart';
import '../services/db.dart';


final dbHelper = DatabaseHelper();

class Buslist extends StatefulWidget {
  final String ?routeName;
  final String ?busNumber;
  final String ?stop;
  final DateTime ?date;
   const Buslist({super.key, this.routeName,this.busNumber,this.stop,this.date,});

  @override
  State<Buslist> createState() => _BuslistState();
}

class _BuslistState extends State<Buslist> {
  late var list,title;
  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }
   void _loadRoutes() {
    if(widget.routeName!=null){
  list = dbHelper.searchBusData(query:widget.routeName!,field:SearchField.route);
  title=widget.routeName!;
    }
  else  if(widget.busNumber!=null){
  list = dbHelper.searchBusData(query:widget.busNumber!,field: SearchField.busNumber );
  title=widget.busNumber!;
    }
    if(widget.date!=null){
  list = dbHelper.searchBusData(date:widget.date!,field: SearchField.date);
  title=widget.date!;
    }
   else if(widget.stop!=null){
  list = dbHelper.searchBusData(query:widget.stop!,field: SearchField.busStop );
  title=widget.stop!;
    }
  }

  _busList(){
 return FutureBuilder(
    future:list,
    // initialData: InitialData,
    builder: (BuildContext context, AsyncSnapshot snapshot) {
       if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text('No trips found'));
      }

 var buslist =snapshot.data;
    
 return  ListView.builder(
  itemCount: buslist.length,
  itemBuilder: (context, index) {
   final item = buslist[index];

   var time =DateFormat('h:mma dd/MM/yy').format(DateTime.parse(item.dateTime));

   var c =item.busNumber.toString().toUpperCase();

   var clr =c.contains("AH") || c.contains("AK") ? const Color.fromARGB(255, 82, 188, 85):const Color.fromARGB(255, 187, 213, 240);
   
  return Card(
  color: Colors.white.withOpacity(0.97),
  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
      Navigator.push(context, MaterialPageRoute(builder: (context){
        return SingleTripScreen(id: item.id);
      }));
    },
    child: Row(
      children: [
        Container(
          width: 6,
          height: 90,
          decoration: BoxDecoration(
            color: clr,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'bus-icon-${item.id}',
                      child: Icon(Icons.directions_bus, color: const Color.fromARGB(255, 109, 162, 255)),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "${item.busNumber}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      "$time",
                      style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                    ),
                  ],
                ),
                if(item.destination.toString().trim()!=''&&item.destination!=null) ...[
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.deepOrange),
                    SizedBox(width: 4),
                    Text(
                      "${item.source} → ${item.destination}",
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                )
                ],
                if(item.videos!=null||item.photos!=null) ...[
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.burst_mode_outlined,size: 24,)
                ],
              )]
              ],
            ),
          ),
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              final x = await showDeleteBox(context);
              if (x) {
                await dbHelper.deleteTrip(item.id);
                setState(() {
                  _loadRoutes();
                });
                showSuccessBox(context, "Deleted ${item.busNumber}");
              }
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        SizedBox(width: 8),
      ],
    ),
  ),
);
 },
 );
    },
  );
 
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$title  List"),),
      body: _busList(),
    );
  }
}