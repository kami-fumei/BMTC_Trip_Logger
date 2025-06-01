// ignore: unused_import
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:trip_logger/utils/utils.dart';
import 'utils/helperdb.dart';
import '../qr.dart';
import '../form.dart';
import '../buslist.dart';
import '../services/db.dart';
import 'search_page.dart';

 final dbHelper =  DatabaseHelper() ;
 

void main() => runApp(
  MaterialApp(
    home: const Busapp(),
    routes: {'/qr': (context) => QRview(), '/add': (context) => AddTripForm()},
  ),
);

class App extends StatelessWidget {
  const App({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Busapp();
  }
}

class Busapp extends StatefulWidget {
  const Busapp({super.key});

  @override
  State<Busapp> createState() => _BusappState();
}

class _BusappState extends State<Busapp> {

 late var _routeFuture;
   @override
  void initState() {
    super.initState();
     _loadRoutes();
    //  dbHelper.ensureSearchHistoryTable();
  }
   void _loadRoutes() {
    _routeFuture = dbHelper.getRouteSummary();
  }

   void setS() {
    setState(() {
      _loadRoutes();  // reload your Future or data
    });
  }
  void perBus(String? busno)async{
    if(busno!=null){
   List<Map<String, dynamic>> summary=await dbHelper.previouslyTraveled(busno);

   if(summary[0]['total_travels']>1){
   await showAlreadyTraveledDialog(context,busno,summary);
   }
   }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Row(
          children: [
            Text("Bus app "),
             Icon(Icons.alt_route_sharp),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search_sharp),
            onPressed: () async {
              // var snapshot = await _routeFuture;
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SearchPage(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () async {
              final busno = await Navigator.pushNamed(context, '/qr');
              if(busno!=null){
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddTripForm(busno: busno as String),
                ),
              ).then((_) => setS());
              }
            },
            icon: Icon(Icons.qr_code_scanner_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var busno = await Navigator.pushNamed(context, '/add');
          if (busno != null) {
            perBus("$busno");
            setS();
          }
        },
        child: Icon(Icons.add),
      ),
      body: _bulidRouts(),
    );
  }

  _bulidRouts() {
    return FutureBuilder(
      future: _routeFuture,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No trips found'));
        }
        var bus = snapshot.data!;
     
        // Filter by search query
       
        return ListView.builder(
          itemCount: bus.length,
          itemBuilder: (context, i) {
            final item = bus[i];
            String formatted = DateFormat('dd/MM/yy').format(DateTime.parse(item["last_traveled"]));
            return Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: Icon(Icons.directions_bus_rounded),
                title: Text("${item["route_name"]}"),
                trailing: IconButton(
                  onPressed: () async {
                    final busno = await Navigator.pushNamed(context, '/qr');
                    if (busno != null) {
                      try {
                        await insertTripWithFields(
                          busNumber: "$busno",
                          routeName: "${item["route_name"]}",
                          dateTime: DateTime.now(),
                        );
                        setS();
                        perBus("$busno");
                        showSuccessBox(context, "$busno");
                      } catch (e) {
                        dialogBox(context, "fail", Colors.red, "bye $e");
                      }
                    }
                  },
                  icon: Icon(Icons.bolt_outlined),
                ),
                subtitle: Text(
                  "no of travels ${item["total_trips"]} \nlast bus taken $formatted ",
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Buslist(routeName: item["route_name"]),
                    ),
                  ).then((_) => setS());
                },
              ),
            );
          },
        );
      },
    );
  }
}
