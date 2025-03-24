import 'package:flutter/material.dart';
import 'package:pica_oauth_client/picaos_auth.dart';

class AuthKitDialog extends StatelessWidget {
  final Function(String) onAuthSuccess;
  final VoidCallback? onClose;
  final String previewUrl;

  const AuthKitDialog({
    required this.onAuthSuccess,
    required this.previewUrl,
    this.onClose,
    super.key,
  });

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
            previewUrl: previewUrl,
            onAuthSuccess: (data) {
              debugPrint('Auth success data received: $data');
              onAuthSuccess(data);
            },
            onClose: () {
              debugPrint('Auth dialog closed');
              // Call the onClose callback if provided
              onClose?.call();
              Navigator.of(context).pop(); // Close the dialog when modal closes
            },
          ),
        ),
      ),
    );
  }
}
