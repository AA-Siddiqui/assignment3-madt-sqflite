import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../helpers/database_helper.dart';
import '../models/location_note.dart';

class LocationService with ChangeNotifier {
  List<LocationNote> _locations = [];

  List<LocationNote> get locations => _locations;

  Future<void> loadLocations(int userId) async {
    _locations = await DatabaseHelper.instance.getLocationNotes(userId);
    notifyListeners();
  }

  Future<bool> addLocation({
    required int userId,
    required String name,
    String? description,
    XFile? imageFile,
  }) async {
    try {
      String? imagePath;

      if (imageFile != null) {
        imagePath = await _saveImage(imageFile);
      }

      final location = LocationNote(
        userId: userId,
        name: name,
        description: description,
        imagePath: imagePath,
      );

      final id = await DatabaseHelper.instance.createLocationNote(location);

      if (id > 0) {
        final newLocation = LocationNote(
          id: id,
          userId: userId,
          name: name,
          description: description,
          imagePath: imagePath,
        );

        _locations.add(newLocation);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Add location error: $e');
      return false;
    }
  }

  Future<bool> updateLocation({
    required LocationNote location,
    String? name,
    String? description,
    XFile? newImageFile,
    bool deleteImage = false,
  }) async {
    try {
      String? imagePath = location.imagePath;

      // Handle the image
      if (deleteImage) {
        if (imagePath != null) {
          await _deleteImage(imagePath);
          imagePath = null;
        }
      } else if (newImageFile != null) {
        // Delete old image if exists
        if (imagePath != null) {
          await _deleteImage(imagePath);
        }
        // Save new image
        imagePath = await _saveImage(newImageFile);
      }

      final updatedLocation = LocationNote(
        id: location.id,
        userId: location.userId,
        name: name ?? location.name,
        description: description ?? location.description,
        imagePath: imagePath,
      );

      final result =
          await DatabaseHelper.instance.updateLocationNote(updatedLocation);

      if (result > 0) {
        final index = _locations.indexWhere((loc) => loc.id == location.id);
        if (index != -1) {
          _locations[index] = updatedLocation;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Update location error: $e');
      return false;
    }
  }

  Future<bool> deleteLocation(LocationNote location) async {
    try {
      final result =
          await DatabaseHelper.instance.deleteLocationNote(location.id!);

      if (result > 0) {
        // Delete the associated image if exists
        if (location.imagePath != null) {
          await _deleteImage(location.imagePath!);
        }

        _locations.removeWhere((loc) => loc.id == location.id);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Delete location error: $e');
      return false;
    }
  }

  Future<String> _saveImage(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final filename = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '${directory.path}/$filename';

    await File(image.path).copy(path);
    return path;
  }

  Future<void> _deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}
