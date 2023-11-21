import 'dart:io';
import 'package:capydoc/screens/docs.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RestrictedScreen extends StatefulWidget {
  const RestrictedScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _RestrictedScreen();
  }
}

class _RestrictedScreen extends State<RestrictedScreen> {
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
              .child('private_documents/${user.uid}/$fileName');

          UploadTask uploadTask = storageReference.putFile(selectedFile);
          await uploadTask.whenComplete(() async {
            String documentUrl = await storageReference.getDownloadURL();
            storeDocumentInfo(user.uid, documentUrl);
          });
        }
      }
    } catch (e) {
      print(e.toString());
    }
  }

  void storeDocumentInfo(String userId, String documentUrl) {
    FirebaseFirestore.instance.collection('private documents').add({
      'userId': userId,
      'documentUrl': documentUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        ],
        title: const Text('Check your private documents'),
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
                    .collection('private documents')
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
                          subtitle: Text(documents[index]['documentUrl']),
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
}
