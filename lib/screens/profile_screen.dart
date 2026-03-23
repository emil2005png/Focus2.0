import 'dart:io';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  String? _photoUrl;
  String? _email;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _currentUsername;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
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

    _profileSubscription = _firestoreService.getUserProfile().listen((snapshot) {
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
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);

      if (image == null) return;

      setState(() => _isLoading = true);

      final downloadUrl = await _firestoreService.uploadProfileImage(File(image.path));

      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newUsername = _usernameController.text.trim();

      if (newUsername != _currentUsername) {
        final isAvailable = await _firestoreService.isUsernameAvailable(newUsername);
        if (!isAvailable) {
          throw Exception('Username is already taken');
        }
      }

      await _firestoreService.updateUserProfile({
        'username': newUsername,
        'age': _ageController.text.trim(),
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
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ── Custom App Bar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 48), // balance for settings icon
                  Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.settings_outlined,
                      color: Colors.grey[900],
                    ),
                    onPressed: _toggleEdit,
                  ),
                ],
              ),
            ),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Avatar & Name Section ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                        child: Column(
                          children: [
                            // Avatar with ring
                            GestureDetector(
                              onTap: _isEditing ? _uploadImage : null,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 128,
                                    height: 128,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primaryColor.withValues(alpha: 0.15),
                                        width: 4,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage:
                                          _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                                      child: _photoUrl == null
                                          ? Icon(Icons.person, size: 56, color: Colors.grey[400])
                                          : null,
                                    ),
                                  ),
                                  if (_isEditing)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.camera_alt,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Name & Username
                            Text(
                              _usernameController.text.isNotEmpty
                                  ? _usernameController.text
                                  : 'Your Name',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _usernameController.text.isNotEmpty
                                  ? '@${_usernameController.text.toLowerCase().replaceAll(' ', '_')}'
                                  : '@username',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Edit Profile Button
                            if (!_isEditing)
                              SizedBox(
                                width: 160,
                                height: 44,
                                child: ElevatedButton.icon(
                                  onPressed: _toggleEdit,
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: Text('Edit Profile',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold, fontSize: 14)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: primaryColor.withValues(alpha: 0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Account Information Section ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 12),
                              child: Text(
                                'ACCOUNT INFORMATION',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),

                            // Email (always read-only)
                            _buildInfoCard(
                              icon: Icons.mail_outlined,
                              label: 'Email Address',
                              value: _email ?? 'Loading...',
                              color: primaryColor,
                            ),
                            const SizedBox(height: 10),

                            // Username
                            _isEditing
                                ? _buildEditableCard(
                                    icon: Icons.alternate_email,
                                    label: 'Username',
                                    controller: _usernameController,
                                    color: primaryColor,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a username';
                                      }
                                      if (value.length < 3) {
                                        return 'Min. 3 characters';
                                      }
                                      return null;
                                    },
                                  )
                                : _buildInfoCard(
                                    icon: Icons.alternate_email,
                                    label: 'Username',
                                    value: _usernameController.text.isNotEmpty
                                        ? _usernameController.text
                                        : 'Not set',
                                    color: primaryColor,
                                  ),
                            const SizedBox(height: 10),

                            // Gender
                            _isEditing
                                ? _buildGenderDropdownCard(primaryColor)
                                : _buildInfoCard(
                                    icon: Icons.person_outline,
                                    label: 'Gender',
                                    value: _genderController.text.isNotEmpty
                                        ? _genderController.text
                                        : 'Not set',
                                    color: primaryColor,
                                  ),
                            const SizedBox(height: 10),

                            // Age
                            _isEditing
                                ? _buildAgeTapCard(primaryColor)
                                : _buildInfoCard(
                                    icon: Icons.cake_outlined,
                                    label: 'Age',
                                    value: _ageController.text.isNotEmpty
                                        ? _ageController.text
                                        : 'Not set',
                                    color: primaryColor,
                                  ),
                          ],
                        ),
                      ),

                      // ── Save Button (Edit Mode) ──
                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: primaryColor.withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : Text('Save Changes',
                                      style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ),

                      // ── Logout Button ──
                      if (!_isEditing)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await _authService.signOut();
                              },
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: Text('Log Out',
                                  style: GoogleFonts.outfit(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  )),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.red.withValues(alpha: 0.04),
                                side: BorderSide(color: Colors.red.withValues(alpha: 0.15)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Version text
                      if (!_isEditing)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            'Version 2.4.0',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),

                      const SizedBox(height: 100), // Bottom padding for floating nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Read-Only Info Card ──
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Editable Text Card ──
  Widget _buildEditableCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required Color color,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  validator: validator,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Gender Dropdown Card ──
  Widget _buildGenderDropdownCard(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.person_outline, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GENDER',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: _genderController.text.isNotEmpty &&
                          ['Male', 'Female', 'Other'].contains(_genderController.text)
                      ? _genderController.text
                      : null,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                  ),
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[900],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please select gender';
                    return null;
                  },
                  items: ['Male', 'Female', 'Other'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _genderController.text = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Age Tap Card ──
  Widget _buildAgeTapCard(Color color) {
    return GestureDetector(
      onTap: () {
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
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done')),
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
                            : 17,
                      ),
                      children: List<Widget>.generate(100, (int index) {
                        return Center(child: Text((index + 1).toString()));
                      }),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.cake_outlined, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AGE',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _ageController.text.isNotEmpty ? _ageController.text : 'Tap to select',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
