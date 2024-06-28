import 'package:flutter/material.dart';
import 'package:flutterbasics/pages/ChatScreen.dart';

class DashBoardScreen extends StatelessWidget {
  final List<Map<String, String>> items = [
    {"name": "Viishhnu", "time": "08:43", "role": "CR of our class"},
    {"name": "Rishikesh", "time": "09:00", "role": "Topper"},
    {"name": "Sainath", "time": "09:00", "role": "Leader"},
    {"name": "Sai", "time": "09:00", "role": "Good"},
    {"name": "Sai", "time": "09:00", "role": "Good"},
    {"name": "Sai", "time": "09:00", "role": "Good"},
    {"name": "Sai", "time": "09:00", "role": "Good"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Container(
              height: 70,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/logo.jpg'),
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.blueGrey,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = items[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item["name"]!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      item["time"]!,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item["role"]!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                // const Divider(
                                //   color: Colors.black,
                                //   thickness: 1,
                                // )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
