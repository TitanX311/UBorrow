import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String name;
  // final String lastMessage;
  // final String time;
  final VoidCallback? onTap;
  final String? imageUrl;

  const UserTile({
    super.key,
    required this.name,
    // required this.lastMessage,
    // required this.time,
    this.onTap,
    this.imageUrl,
    required text,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            /// Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: imageUrl != null
                  ? NetworkImage(imageUrl!)
                  : null,
              child: imageUrl == null
                  ? const Icon(Icons.person, size: 28, color: Colors.white)
                  : null,
            ),

            const SizedBox(width: 12),

            /// Name + Last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // const SizedBox(height: 4),
                  // Text(
                  //   lastMessage,
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     color: Colors.grey.shade600,
                  //   ),
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  // ),
                ],
              ),
            ),

            /// Time
            // Text(
            //   time,
            //   style: TextStyle(
            //     fontSize: 12,
            //     color: Colors.grey.shade500,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
