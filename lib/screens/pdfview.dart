import 'package:capydoc/screens/docs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PdfviewScreen extends StatefulWidget {
  const PdfviewScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _PdfviewScreenState();
  }
}

class _PdfviewScreenState extends State<PdfviewScreen> {
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
        title: Text('PDF View'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('documents').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, i) {
                QueryDocumentSnapshot x = snapshot.data!.docs[i];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Text(x['documentUrl']),
                );
              },
            );
          }

          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
