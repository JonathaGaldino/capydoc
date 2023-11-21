import 'dart:io';

import 'package:capydoc/screens/pdfview.dart';
import 'package:capydoc/screens/profile.dart';
import 'package:capydoc/screens/restricted.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class DocsScreen extends StatefulWidget {
  @override
  _DocsScreenState createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  List<File> _selectedFiles = [];
  final _passwordController = TextEditingController();
  var _enteredPassword = '';

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedFiles = result.paths!.map((path) => File(path!)).toList();
      });
    }
  }

  Future<void> _uploadDocuments() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        for (File selectedFile in _selectedFiles) {
          String fileName = selectedFile.path.split('/').last;
          Reference storageReference = FirebaseStorage.instance
              .ref()
              .child('documents/${user.uid}/$fileName');

          UploadTask uploadTask = storageReference.putFile(selectedFile);
          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
          String documentUrl = await taskSnapshot.ref.getDownloadURL();

          storeDocumentInfo(user.uid, documentUrl);
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void storeDocumentInfo(String userId, String documentUrl) {
    FirebaseFirestore.instance.collection('documents').add({
      'userId': userId,
      'documentUrl': documentUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _showPasswordDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Password'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String enteredPassword = _passwordController.text;
                try {
                  UserCredential userCredential =
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: FirebaseAuth.instance.currentUser?.email ?? '',
                    password: enteredPassword,
                  );

                  if (userCredential.user != null) {
                    Navigator.pop(context);
                    _proceedToDocumentPage();
                  } else {
                    print('Authentication failed');
                  }
                } catch (e) {
                  print('Authentication error: $e');
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _proceedToDocumentPage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => RestrictedScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check your documents'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            onPressed: () async {
              await _showPasswordDialog(context);
            },
            icon: Icon(
              Icons.lock,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('documents')
                    .where('userId',
                        isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  List<DocumentSnapshot> documents = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Document ${index + 1}'),
                          subtitle: InkWell(
                              child: Text('Open Document'),
                              onTap: () async {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => PdfviewScreen(),
                                  ),
                                );
                              }),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickDocument,
                    child: const Text('Pick Documents'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _uploadDocuments,
                    child: const Text('Upload Documents'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showAlertDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Erro'),
          content: Text('Erro ao abrir o documento. Detalhes: $errorMessage'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
