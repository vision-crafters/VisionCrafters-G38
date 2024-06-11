import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        children: [
          ListTile(
            title: const Text('Account'),
            leading: const Icon(Icons.account_circle),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Help'),
            leading: const Icon(Icons.help),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Privacy'),
            leading: const Icon(Icons.lock),
            onTap: () {},
          ),
          ListTile(
            title: const Text('About'),
            leading: const Icon(Icons.info),
            onTap: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                // Add your action here
              },
            ),
            const Text(
              '© Vision Crafters',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
