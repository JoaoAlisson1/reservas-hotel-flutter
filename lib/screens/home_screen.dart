import 'package:dormez_app/screens/quarto_list_screen.dart';
import 'package:dormez_app/screens/reserva_list_screen.dart';
import 'package:flutter/material.dart';
import '../core/authentication/auth_service.dart';
import 'funcionario_list_screen.dart';
import 'hospede_list_screen.dart';
import 'usuarios_list_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final usuarioLogado = authService.usuarioLogado;
    final bool isAdmin = authService.ehAdmin;
    String cargoDisplay = isAdmin ? 'Administrador' : 'Recepcionista';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dormez Hotel'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sair do Sistema',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Olá,",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                Text(
                  usuarioLogado?.login ?? "Usuário",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Nível: $cargoDisplay",
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),

          // Menu em Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuItem(
                    context,
                    title: 'Reservas',
                    icon: Icons.calendar_month,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReservaListScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'Quartos',
                    icon: Icons.bed,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QuartoListScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'Hóspedes',
                    icon: Icons.people,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HospedeListScreen()),
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    title: 'Funcionários',
                    icon: Icons.badge,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FuncionarioListScreen()),
                      );
                    },
                  ),
                  if (isAdmin)
                    _buildMenuItem(
                      context,
                      title: 'Config. Usuários',
                      icon: Icons.admin_panel_settings,
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const UsuariosListScreen()),
                        );
                      },
                    ),

                  _buildMenuItem(
                    context,
                    title: 'Sair do Sistema',
                    icon: Icons.logout,
                    color: Colors.grey,
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    AuthService().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}