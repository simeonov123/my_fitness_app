import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/pending_client_invite_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override State<SplashPage> createState() => _SplashState();
}

class _SplashState extends State<SplashPage> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final auth = context.read<AuthProvider>();
    _boot(auth);
  }

  Future<void> _boot(AuthProvider auth) async {
    final pendingInvite = await PendingClientInviteService().readToken();
    if (!mounted) return;

    await auth.loginOrSignup(interactive: false);
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      pendingInvite != null && pendingInvite.isNotEmpty && !auth.isAuthenticated
          ? '/onboard/client?token=$pendingInvite'
          : auth.isAuthenticated
              ? '/home'
              : '/login',
    );
  }

  @override
  Widget build(BuildContext c) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
