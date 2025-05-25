import 'package:flutter/material.dart';

class PostButton extends StatelessWidget {
  final void Function()? onTap;

  const PostButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(15),
        margin: const EdgeInsets.only(left: 10),
        child: Center(
          child: Icon(
            Icons.done_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
