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
    if (!mounted) {
      return;
    }
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
    if (mounted) {
      setState(() => chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon VPN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mdp,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Mot de passe (6 caractères minimum)'),
            ),
            const SizedBox(height: 24),
            if (chargement)
              const CircularProgressIndicator()
            else ...[
              FilledButton(
                onPressed: () => envoyer(false),
                child: const Text('Se connecter'),
              ),
              TextButton(
                onPressed: () => envoyer(true),
                child: const Text('Créer un compte'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String statut = 'chargement';
  DateTime? expire;

  @override
  void initState() {
    super.initState();
    charger();
  }

  Future<void> charger() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      final data = await supabase
          .from('abonnements')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();
      if (!mounted) {
        return;
      }
      setState(() {
        statut = (data?['statut'] as String?) ?? 'inactif';
        final e = data?['expire_le'] as String?;
        expire = e != null ? DateTime.parse(e) : null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => statut = 'erreur');
    }
  }

  bool get actif =>
      statut == 'admin' ||
      (statut == 'actif' && expire != null && expire!.isAfter(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';
    String texte;
    if (statut == 'chargement') {
      texte = 'Chargement...';
    } else if (statut == 'erreur') {
      texte = 'Impossible de lire votre abonnement.';
    } else if (actif) {
      texte = 'Abonnement actif ✅';
    } else {
      texte = 'Abonnement inactif. Abonnez-vous pour vous connecter.';
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon VPN'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(email),
              const SizedBox(height: 16),
              Text(texte, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: actif ? () {} : null,
                child: const Text('Se connecter au VPN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
