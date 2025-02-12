import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String imagePath;
  final String label;
  final void Function() onTap;

  const CategoryIcon({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: 10.0), // Adds spacing between icons
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular Image
            Container(
              width: 70.0, // Size of the circle
              height: 70.0, // Size of the circle
              decoration: BoxDecoration(
                shape: BoxShape.circle, // Makes the image circular
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Label under the icon
            SizedBox(height: 5.0), // Adds space between the image and the label
            Text(
              label,
              textAlign: TextAlign.center, // Centers the label
            ),
          ],
        ),
      ),
    );
  }
}
