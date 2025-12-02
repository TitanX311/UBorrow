import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final user;

  ChatScreen({super.key, required this.user});

  final msgCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${user["name"]}")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(12),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("Okay, come to my room."),
                  ),
                ),
                SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("I’m coming!"),
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: msgCtrl,
                  decoration: InputDecoration(
                    hintText: "Type message...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                onPressed: () {},
              )
            ],
          )
        ],
      ),
    );
  }
}
