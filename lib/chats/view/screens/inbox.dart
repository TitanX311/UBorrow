import 'package:flutter/material.dart';

class InBox extends StatelessWidget {
  InBox({super.key, required this.user});

  final msgCtrl = TextEditingController();
  final String user;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with $user")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text("Okay, come to my room."),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text("I’m coming!"),
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
                  decoration: const InputDecoration(
                    hintText: "Type message...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {},
              )
            ],
          )
        ],
      ),
    );
  }
}