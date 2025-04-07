import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'location_form_screen.dart';
import 'location_detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final locationService = context.read<LocationService>();

    if (authService.currentUser != null) {
      await locationService.loadLocations(authService.currentUser!.id!);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final locationService = context.watch<LocationService>();
    final locations = locationService.locations;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Locations'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              authService.logout();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : locations.isEmpty
              ? Center(
                  child: Text(
                    'No locations saved yet.\nTap + to add a new location.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return Dismissible(
                      key: Key(location.id.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Location'),
                            content: Text(
                                'Are you sure you want to delete this location?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        locationService.deleteLocation(location);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Location deleted')),
                        );
                      },
                      child: ListTile(
                        leading: location.imagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  File(location.imagePath!),
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[300],
                                child: Icon(Icons.location_on,
                                    color: Colors.grey[600]),
                              ),
                        title: Text(location.name),
                        subtitle: location.description != null &&
                                location.description!.isNotEmpty
                            ? Text(
                                location.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LocationDetailScreen(location: location),
                            ),
                          );
                          _loadLocations();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LocationFormScreen()),
          );
          _loadLocations();
        },
      ),
    );
  }
}
