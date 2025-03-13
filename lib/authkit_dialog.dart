import 'package:flutter/material.dart';
import 'package:pica_oauth_client/picaos_auth.dart';

class AuthKitDialog extends StatelessWidget {
  final Function(String) onAuthSuccess;

  const AuthKitDialog({required this.onAuthSuccess, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    double dialogWidth = 300.0;
    double dialogHeight = 400.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: const BoxDecoration(color: Colors.white),
          child: PicaOSAuthWebview(
            previewUrl:
                'https://pica-authkit-steve.vercel.app?connection-id=67d146df1450e35979d8c768&user-id=671b691a2a7d8b8b1e766357',
            onAuthSuccess: (data) {
              debugPrint('Auth success data received: $data');
              onAuthSuccess(data);
            },
            onClose: () {
              debugPrint('Auth dialog closed');
              Navigator.of(context).pop(); // Close the dialog when modal closes
            },
          ),
        ),
      ),
    );
  }
}
