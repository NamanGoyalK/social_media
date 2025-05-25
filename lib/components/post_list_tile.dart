import 'package:flutter/material.dart';

class PostListTile extends StatelessWidget {
  final String title;
  final String subTitle;
  final String postedAt; // Added new property for "posted at"

  const PostListTile({
    super.key,
    required this.title,
    required this.subTitle,
    required this.postedAt, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "${DateTime.parse(postedAt).hour.toString().padLeft(2, '0')}:${DateTime.parse(postedAt).minute.toString().padLeft(2, '0')} | ${DateTime.parse(postedAt).day.toString().padLeft(2, '0')}/${DateTime.parse(postedAt).month.toString().padLeft(2, '0')}/${DateTime.parse(postedAt).year.toString().substring(2)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
