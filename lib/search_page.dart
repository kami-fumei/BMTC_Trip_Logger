// ignore: unused_import
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trip_logger/buslist.dart';
import './services/db.dart';

final dbHelper = DatabaseHelper();

enum SearchField { all, route, busNumber, date, busStop }

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SearchController _controller = SearchController();
  String _query = '';
  SearchField _selectedField = SearchField.all;
  DateTime? _pickedDate;
  late List<String> _searchHistory = [];
  bool _showHistory = true;

  Future _fetchResults() async {

    var r =  await dbHelper.getFilteredSearchFieldValues(
      query: _query,
      field: _selectedField,
      date: _pickedDate,
    );
    return r;
  }

  void _showFilterDialog() async {
    final selected = await showDialog<SearchField>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text('Search in'),
            children: [
              SimpleDialogOption(
                child: Text('All Fields'),
                onPressed: () => Navigator.pop(context, SearchField.all),
              ),
              SimpleDialogOption(
                child: Text('Bus Route'),
                onPressed: () => Navigator.pop(context, SearchField.route),
              ),
              SimpleDialogOption(
                child: Text('Bus Number'),
                onPressed: () => Navigator.pop(context, SearchField.busNumber),
              ),
              SimpleDialogOption(
                child: Text('Date'),
                onPressed: () => Navigator.pop(context, SearchField.date),
              ),
              SimpleDialogOption(
                child: Text('Bus Stop'),
                onPressed: () => Navigator.pop(context, SearchField.busStop),
              ),
            ],
          ),
    );
    if (selected != null) {
      setState(() {
        _selectedField = selected;
        _query = '';
        _controller.clear();
        if (_selectedField == SearchField.date) {
          _pickDate();
        } else {
          _pickedDate = null;
        }
      });
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _pickedDate = picked;
        _showHistory = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  void _loadSearchHistory() async {
    final history = await dbHelper.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  void _addToHistory(String query) async {
    if (query.isEmpty) return;
    await dbHelper.addSearchHistory(query);
    _loadSearchHistory();
  }

  void _deleteFromHistory(String query) async {
    await dbHelper.deleteSearchHistory(query);
    _loadSearchHistory();
  }

  void _clearHistory() async {
    await dbHelper.clearSearchHistory();
    _loadSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    String filterLabel;
    switch (_selectedField) {
      case SearchField.all:
        filterLabel = "All Fields";
        break;
      case SearchField.route:
        filterLabel = "Bus Route";
        break;
      case SearchField.busNumber:
        filterLabel = "Bus Number";
        break;
      case SearchField.date:
        filterLabel = "Date";
        break;
      case SearchField.busStop:
        filterLabel = "Bus Stop";
        break;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Search')),
      body: Column(
        children: [
          if (_selectedField == SearchField.date && _pickedDate != null)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Date: ${_pickedDate!.day}/${_pickedDate!.month}/${_pickedDate!.year}",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_calendar),
                  onPressed: _pickDate,
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBar(
                controller: _controller,
                hintText: 'Search...',
                onChanged: (value) {
                  setState(() {
                    _query = value;
                    _showHistory = value.isEmpty;
                  });
                },
                onTap: () {
                  setState(() {
                    if (_query.isEmpty) _showHistory = true;
                  });
                },
                onSubmitted: (value) {
                  setState(() {
                    _query = value;
                    _showHistory = false;
                  });
                  _addToHistory(value);
                },
                trailing: [
                  IconButton(
                    icon: Icon(Icons.filter_list),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filter ($filterLabel)',
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _showHistory = true;
                        _query = '';
                        _controller.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          // The rest of your body: history or results
          Expanded(
            child:
                _showHistory && _searchHistory.isNotEmpty
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Search History',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              TextButton(
                                onPressed: _clearHistory,
                                child: Text('Clear All'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _searchHistory.length,
                            itemBuilder: (context, index) {
                              final h = _searchHistory[index];
                              return ListTile(
                                leading: Icon(Icons.history),
                                title: Text(h),
                                onTap: () {
                                  setState(() {
                                    _controller.text = h;
                                    _query = h;
                                    _showHistory = false;
                                  });
                                },
                                trailing: IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () => _deleteFromHistory(h),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )
                    : FutureBuilder(
                      future: (_query.isEmpty && _selectedField != SearchField.date)
                              ? Future.value([])
                              : _fetchResults(),
                      builder: (context, snapshot) {
                      
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        final data = snapshot.data ?? [];
                       
                        // if (data.isEmpty) {
                        //   return Center(child: Text('No results found.'));
                        // }
                        //  if (data['route'].isEmpty && data['busNumber'].isEmpty && data['date'].isEmpty && data['busStop'].isEmpty) {
                        //   return Center(child: Text('No results found.'));
                        // }
                        if (data.isEmpty ||
                            (data is Map &&
                                data.values.every(
                                  (v) => v.toList().isEmpty,
                                ))) {
                          return Center(child: Text('No results found.'));
                        }

                        List<Widget> sections = [];

                        // Helper for section headline
                        Widget sectionHeader(
                          String title,
                          IconData icon,
                        ) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        );

                        // Bus Routes Section
                        if ((_selectedField == SearchField.route ||
                                _selectedField == SearchField.all) &&
                            data['route'].isNotEmpty) {
                          sections.add(
                            sectionHeader('Bus Routes', Icons.alt_route),
                          );
                          data['route'].forEach((route) {
                            sections.add(
                              GestureDetector(
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => Buslist(routeName: route),
                                      ),
                                    ),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.directions_bus,
                                      color: Colors.blue,
                                    ),
                                    title: Text(
                                      route,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          });
                        }

                        // Bus Numbers Section
                        if ((_selectedField == SearchField.busNumber ||
                                _selectedField == SearchField.all) &&
                            data['busNumber'].isNotEmpty) {
                          sections.add(
                            sectionHeader(
                              'Bus Numbers',
                              Icons.confirmation_number,
                            ),
                          );
                          data['busNumber'].forEach((busNo) {
                            sections.add(
                              GestureDetector(
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => Buslist(busNumber: busNo),
                                      ),
                                    ),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.directions_bus_filled,
                                      color: Colors.green,
                                    ),
                                    title: Text(
                                      busNo,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          });
                        }

                        // Dates Section
                        // if (_selectedField == SearchField.date &&
                        //     data['date'].isNotEmpty) {
                        //   sections.add(
                        //     sectionHeader('Dates', Icons.calendar_today),
                        //   );

                        //   data['date'].forEach((date) {
                        //     sections.add(
                        //       GestureDetector(
                        //         onTap:
                        //             () => Navigator.push(
                        //               context,
                        //               MaterialPageRoute(
                        //                 builder:
                        //                     (_) => Buslist(
                        //                       date: DateTime.parse(date),
                        //                     ),
                        //               ),
                        //             ),
                        //         child: Card(
                        //           margin: const EdgeInsets.symmetric(
                        //             horizontal: 12,
                        //             vertical: 4,
                        //           ),
                        //           child: ListTile(
                        //             leading: Icon(
                        //               Icons.event,
                        //               color: Colors.deepPurple,
                        //             ),
                        //             title: Text(
                        //               date.toString(),
                        //               style: TextStyle(
                        //                 fontWeight: FontWeight.bold,
                        //               ),
                        //             ),
                        //           ),
                        //         ),
                        //       ),
                        //     );
                        //   });
                        // }

                        // Bus Stops Section
                        if ((_selectedField == SearchField.busStop ||
                                _selectedField == SearchField.all) &&
                            data['busStop'].isNotEmpty) {
                          sections.add(
                            sectionHeader('Bus Stops', Icons.location_on),
                          );
                          data['busStop'].forEach((stop) {
                            sections.add(
                              GestureDetector(
                                onTap:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Buslist(stop: stop),
                                      ),
                                    ),
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.location_on,
                                      color: Colors.redAccent,
                                    ),
                                    title: Text(
                                      stop,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          });
                        }

                        return Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.1),
                          child: ListView(children: sections),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
