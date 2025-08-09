import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/textfield.dart';

class EditPost extends StatelessWidget {
  static var routeName = "/editPost";

  const EditPost({super.key});

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    var texttheme = Theme.of(context).textTheme;
    var nav = Navigator.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        title: Text(
          "Edit Post",
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: texttheme.headlineMedium!.fontSize,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              nav.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.tertiaryContainer,
              foregroundColor: scheme.onTertiaryContainer,
            ),
            child: Text("Confirm Edit"),
          ),
          SizedBox(width: 20),
        ],
      ),

      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 15),
        child: ElevatedButton.icon(
          onPressed: () {},

          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
          ),
          icon: CircleAvatar(
            backgroundColor: scheme.onPrimaryContainer,
            radius: 14,
            child: CircleAvatar(radius: 12, child: Icon(Icons.add)),
          ),

          label: Text("Add Image"),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: Form(
        child: Container(
          margin: EdgeInsets.all(15),
          padding: EdgeInsets.fromLTRB(10, 5, 10, 0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainerHigh,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              BorderlessField(
                child: TextFormField(
                  maxLines: null,
                  style: TextStyle(fontSize: texttheme.headlineLarge!.fontSize),
                  decoration: InputDecoration.collapsed(
                    hintText: "Add post title",
                  ),
                  initialValue: "Post title",
                ),
              ),

              SizedBox(height: 10),

              BorderlessField(
                child: TextFormField(
                  maxLines: null,
                  decoration: InputDecoration.collapsed(
                    hintText: "Add description",
                  ),
                  initialValue:
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
