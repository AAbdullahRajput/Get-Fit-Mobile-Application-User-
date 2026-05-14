import 'package:flutter/material.dart';

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 0,
      color: Color(0xff2C2C2E),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('John Doe (4.5)',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              trailing: Text("2d ago",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            Padding(
              padding: EdgeInsets.only(left: 14),
              child: Text(
                  "Great trainer! Helped me achieve my fitness goals in no time.",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
