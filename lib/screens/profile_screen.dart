import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_app/widgets/custom_text_field.dart'; // Assuming we can reuse or use standard fields

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController(); // Could be a dropdown
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  String? _photoUrl;
  String? _email;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _currentUsername; // To check if username changed

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = _authService.currentUser;
    setState(() {
      _email = user?.email;
    });

    _firestoreService.getUserProfile().listen((snapshot) {
      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _currentUsername = data['username'];
          _ageController.text = data['age']?.toString() ?? '';
          _genderController.text = data['gender'] ?? '';
          _photoUrl = data['photoUrl'];
        });
      }
    });
  }

  Future<void> _uploadImage() async {
    // Temporarily disabled due to storage config issues
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('Profile picture upload will arrive in the next update!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newUsername = _usernameController.text.trim();
      
      // Check username uniqueness only if changed
      if (newUsername != _currentUsername) {
        final isAvailable = await _firestoreService.isUsernameAvailable(newUsername);
        if (!isAvailable) {
          throw Exception('Username is already taken');
        }
      }

      await _firestoreService.updateUserProfile({
        'username': newUsername,
        'age': _ageController.text.trim(), // Store as string for flexibility or parse int
        'gender': _genderController.text.trim(),
      });

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                // Reset fields if cancelling? For now just toggle
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: _isEditing ? _uploadImage : null,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _photoUrl != null
                          ? NetworkImage(_photoUrl!)
                          : null,
                      child: _photoUrl == null
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Email (Read Only)
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Email'),
                subtitle: Text(_email ?? 'Loading...'),
              ),
              const Divider(),

              // Username
              TextFormField(
                controller: _usernameController,
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a username';
                  if (value.length < 3) return 'Username must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Age Wheel Picker
              GestureDetector(
                onTap: _isEditing
                    ? () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SizedBox(
                              height: 250,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Done'),
                                      ),
                                    ],
                                  ),
                                  Expanded(
                                    child: CupertinoPicker(
                                      itemExtent: 32.0,
                                      onSelectedItemChanged: (int index) {
                                        setState(() {
                                          _ageController.text = (index + 1).toString();
                                        });
                                      },
                                      scrollController: FixedExtentScrollController(
                                        initialItem: int.tryParse(_ageController.text) != null
                                            ? int.parse(_ageController.text) - 1
                                            : 17, // Default to 18 (index 17)
                                      ),
                                      children: List<Widget>.generate(100, (int index) {
                                        return Center(
                                          child: Text((index + 1).toString()),
                                        );
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    : null,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _ageController,
                    enabled: _isEditing, // Visual only, tappable via GestureDetector
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please select your age';
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _genderController.text.isNotEmpty && ['Male', 'Female', 'Other'].contains(_genderController.text)
                    ? _genderController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please select your gender';
                  return null;
                },
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: _isEditing
                    ? (String? newValue) {
                        setState(() {
                          _genderController.text = newValue!;
                        });
                      }
                    : null, // Disable when not editing
              ),
              const SizedBox(height: 32),

              // Save Button
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
