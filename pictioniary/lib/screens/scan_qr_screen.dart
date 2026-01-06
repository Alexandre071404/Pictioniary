import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanCompleted = false;

  // ----------------------------------------------------------------------
  // INDISPENSABLE AVEC CE PACKAGE
  // Gère le redémarrage de la caméra lors du Hot Reload ou changement d'app
  // ----------------------------------------------------------------------
  @override
  void reassemble() {
    super.reassemble();
    // Ne pas utiliser Platform sur le web
    if (kIsWeb) {
      // Sur le web, on ne fait rien car le scanner QR ne fonctionne pas de la même manière
      return;
    }
    // Pour mobile, utiliser une approche conditionnelle
    try {
      // Vérifier la plateforme de manière sécurisée
      if (defaultTargetPlatform == TargetPlatform.android) {
        controller?.pauseCamera();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        controller?.resumeCamera();
      }
    } catch (e) {
      // Ignorer les erreurs de plateforme
      print('Erreur lors de la gestion de la caméra: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    // On écoute le flux de données scannées
    controller.scannedDataStream.listen((scanData) {
      // Debug: afficher le code scanné
      print('QR Code scanné: ${scanData.code}');
      
      // Si on a un code valide et qu'on n'a pas déjà fini
      if (!isScanCompleted && scanData.code != null && scanData.code!.isNotEmpty) {
        final scannedCode = scanData.code!.trim();
        print('Code traité: $scannedCode');
        
        // Vérifier que le widget est toujours monté
        if (!mounted) {
          print('Widget non monté, abandon');
          return;
        }
        
        // Marquer comme scanné immédiatement pour éviter les scans multiples
        isScanCompleted = true;
        
        setState(() {
          // Mise à jour de l'UI
        });

        // On met en pause la caméra immédiatement
        controller.pauseCamera();
        print('Caméra mise en pause');

        // Retourner immédiatement avec le code (pas besoin de délai)
        if (mounted) {
          print('Retour avec le code: $scannedCode');
          // On renvoie le code à la page précédente
          Navigator.of(context).pop(scannedCode);
        } else {
          print('Widget non monté lors du retour');
        }
      } else {
        print('Code invalide ou déjà scanné. Code: ${scanData.code}, isScanCompleted: $isScanCompleted');
      }
    }, onError: (error) {
      print('Erreur lors du scan: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanner le QR Code"),
        backgroundColor: const Color(0xFF667EEA),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF111827)],
          ),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                // Ajout d'un cadre visuel sympa pour guider l'utilisateur
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.red,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 300,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isScanCompleted ? Icons.check_circle : Icons.qr_code_scanner,
                      color: isScanCompleted ? Colors.green : Colors.white,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isScanCompleted ? "QR Code détecté !" : "Visez le QR Code",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isScanCompleted 
                        ? "Retour en cours..." 
                        : "Détection automatique",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Annuler",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


