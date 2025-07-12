import 'package:flutter/material.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/services/user_service.dart';
import 'package:livraisonb2b/constants/theme.dart';

class AdminUsersScreen extends StatefulWidget {
  static const String idScreen = "AdminUsersScreen";

  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<UserApp>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = UserService.getAdmins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: FutureBuilder<List<UserApp>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      user.profileUrl != null
                          ? NetworkImage(user.profileUrl!)
                          : null,
                  child:
                      user.profileUrl == null
                          ? Text(user.firstName?.substring(0, 1) ?? 'U')
                          : null,
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                subtitle: Text(user.phone ?? ''),
                trailing: Switch(
                  value: user.isAdmin,
                  onChanged: (value) => _toggleAdminStatus(user, value),
                  activeColor: AppColors.primaryColor,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleAdminStatus(UserApp user, bool isAdmin) async {
    try {
      if (isAdmin) {
        await UserService.promoteToAdmin(user.id!);
      } else {
        await UserService.demoteFromAdmin(user.id!);
      }
      setState(() {
        user.isAdmin = isAdmin;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    }
  }
}
