import 'package:flutter/material.dart';

bool hide = true;
TextFormField passField({
  bool? obscureText = true,
  Widget? suffixIcon,
  String? hintText,
  TextEditingController? controller,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    obscureText: obscureText ?? true,
    decoration: InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      hintText: hintText,
      suffixIcon: suffixIcon,
    ),
    controller: controller,
    validator: validator,
  );
}

TextFormField textInputan(
  String hint, {
  TextEditingController? kontroller,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    decoration: InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
    controller: kontroller,
    validator: validator,
  );
}

Row judulTextfield(String judul) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Flexible(
        child: Text(
          judul,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
//  TextFormField textInput(
//     String hint, {
//     String? Function(String?)? validator,
//     TextEditingController? kontroller,
//   }) {
//     return TextFormField(
//       decoration: InputDecoration(
//         hintText: hint,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//       controller: kontroller ?? emailC,
//       validator:
//           validator ??
//           (value) {
//             if (value == null || value.isEmpty) {
//               return "Email tidak valid!";
//             }
//             return null;
//           },
//     );
//   }