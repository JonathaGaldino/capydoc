import 'package:capydoc/screens/auth.dart';
import 'package:capydoc/screens/docs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? "");
    _emailController = TextEditingController(text: user?.email ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DocsScreen(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(),
                ),
                (Route<dynamic> route) => false,
              );
            },
            icon: Icon(
              Icons.logout_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isEditMode)
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                )
              else
                Text('Name: ${_nameController.text}'),
              SizedBox(height: 16),
              if (_isEditMode)
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                )
              else
                Text('Email: ${_emailController.text}'),
              SizedBox(height: 16),
              if (_isEditMode)
                ElevatedButton(
                  onPressed: () {
                    User? user = FirebaseAuth.instance.currentUser;
                    user?.updateDisplayName(_nameController.text);
                    user?.updateEmail(_emailController.text);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Profile updated successfully!'),
                      ),
                    );

                    setState(() {
                      _isEditMode = false;
                    });
                  },
                  child: Text('Save Profile'),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditMode = true;
                    });
                  },
                  child: Text('Edit Profile'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
