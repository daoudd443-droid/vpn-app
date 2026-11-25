import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://aydrkkdtsqfatvczmsvx.supabase.co';
const supabaseKey = 'sb_publishable_8eGdCrr5-V7l_uljxgcOpA_swnokpIy';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const VpnApp());
}

class VpnApp extends StatelessWidget {
  const VpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon VPN',
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = supabase.auth.currentSession;
          return session == null ? const AuthPage() : const HomePage();
        },
      ),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final mdp = TextEditingController();
  bool chargement = false;

  void message(String texte) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> envoyer(bool inscription) async {
    setState(() => chargement = true);
    try {
      if (inscription) {
        final res = await supabase.auth
            .signUp(email: email.text.trim(), password: mdp.text);
        if (res.session == null) {
          message('Compte créé. Confirmez votre email, puis connectez-vous.');
        }
      } else {
        await supabase.auth
            .signInWithPassword(email: email.text.trim(), password: mdp.text);
      }
    } on AuthException catch (e) {
      message(e.message);
    } catch (e) {
      message('Erreur de connexion. Vérifiez votre internet.');
    }
    if (mounted
