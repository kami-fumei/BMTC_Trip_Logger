// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ignore: unused_import
import 'package:trip_logger/specific_bus.dart';
import 'package:trip_logger/utils/utils.dart';
import '../services/db.dart';


final dbHelper = DatabaseHelper();

class Buslist extends StatefulWidget {
  final String routeName;
   const Buslist({super.key,required this.routeName});

  @override
  State<Buslist> createState() => _BuslistState();
}

class _BuslistState extends State<Buslist> {
  late var routebuss;
  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }
   void _loadRoutes() {
  routebuss = dbHelper.getTripsByRoute(widget.routeName);
  }

  _busList(){
 return FutureBuilder(
    future:routebuss,
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
  
  // log("$list ${snapshot.data}");
  
 return  ListView.builder(
  itemCount: buslist.length,
  itemBuilder: (context, index) {
   final item = buslist[index];
   var time =DateFormat('h:mma dd/MM/yy').format(DateTime.parse(item.dateTime));
   var c =item.busNumber.toString().toUpperCase();
   var clr =c.contains("AH") || c.contains("AK") ? const Color.fromARGB(255, 82, 188, 85):const Color.fromARGB(255, 187, 213, 240);
  return Card(
    margin: EdgeInsets.all(8),
    color:clr,
    child: ListTile(
      // onTap: () {
      //   Navigator.push(context, MaterialPageRoute(builder: (context){
      //   return  BusDetailScreen(busNumber:"${item.busNumber}");
      //   }));
      // },
      title: Text("${item.busNumber}"),
      subtitle:Text("time $time"),
      
      trailing:Column(
        children: [
          IconButton(onPressed: () async{

        final x = await showDeleteBox(context);
        if(x){
            await dbHelper.deleteTrip(item.id);
            setState(() {
              _loadRoutes(); 
            }); 
            showSuccessBox(context,"Deleted ${item.busNumber}");
        }
          }, icon: Icon(Icons.delete_outline))
        ],
      ) ,
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
      appBar: AppBar(title: Text("${widget.routeName} Route List"),),
      body: _busList(),
    );
  }
}