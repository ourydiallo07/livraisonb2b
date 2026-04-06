// account/select_recipient_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/services/user_service.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:provider/provider.dart';

class SelectRecipientScreen extends StatefulWidget {
  static const String idScreen = "SelectRecipientScreen";

  const SelectRecipientScreen({super.key});

  @override
  State<SelectRecipientScreen> createState() => _SelectRecipientScreenState();
}

class _SelectRecipientScreenState extends State<SelectRecipientScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedOption = 'myself';
  UserApp? _selectedUser;
  List<UserApp> _allUsers = [];
  List<UserApp> _filteredUsers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      print('🔍 Début du chargement des utilisateurs...');

      final collections = ['users', 'USERS', 'utilisateurs', 'clients'];

      for (final collectionName in collections) {
        print('📂 Essai de la collection: $collectionName');
        try {
          final snapshot =
              await FirebaseFirestore.instance
                  .collection(collectionName)
                  .where('isAdmin', isEqualTo: false)
                  .get();

          if (snapshot.docs.isNotEmpty) {
            print(
              '✅ Collection trouvée: $collectionName avec ${snapshot.docs.length} documents',
            );

            final users =
                snapshot.docs.map((doc) {
                  final data = doc.data();
                  UserApp user;
                  try {
                    user = UserApp.fromMap(data, doc.id);
                  } catch (e) {
                    user = UserApp(
                      id: doc.id,
                      firstName:
                          data['firstName'] ??
                          data['firstname'] ??
                          data['name'] ??
                          '',
                      lastName: data['lastName'] ?? data['lastname'] ?? '',
                      phone:
                          data['phone'] ??
                          data['telephone'] ??
                          data['numero'] ??
                          '',
                      isAdmin: data['isAdmin'] ?? false,
                    );
                  }
                  return user;
                }).toList();

            setState(() {
              _allUsers = users;
              _filteredUsers = _allUsers;
              _isLoading = false;
            });

            return;
          }
        } catch (e) {
          print('❌ Erreur avec collection $collectionName: $e');
        }
      }

      // Si aucune collection ne fonctionne, essayer sans filtre
      final snapshotWithoutFilter =
          await FirebaseFirestore.instance.collection('users').get();

      if (snapshotWithoutFilter.docs.isEmpty) {
        throw Exception('Aucun utilisateur trouvé dans aucune collection');
      }

      final users =
          snapshotWithoutFilter.docs.map((doc) {
            final data = doc.data();
            return UserApp(
              id: doc.id,
              firstName:
                  data['firstName'] ??
                  data['firstname'] ??
                  data['name'] ??
                  'Inconnu',
              lastName: data['lastName'] ?? data['lastname'] ?? '',
              phone:
                  data['phone'] ??
                  data['telephone'] ??
                  data['numero'] ??
                  '00000000',
              isAdmin: data['isAdmin'] ?? false,
            );
          }).toList();

      setState(() {
        _allUsers = users;
        _filteredUsers = _allUsers;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur finale chargement utilisateurs: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement: $e';
      });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        final searchLower = query.toLowerCase();
        _filteredUsers =
            _allUsers.where((user) {
              final firstName = user.firstName?.toLowerCase() ?? '';
              final lastName = user.lastName?.toLowerCase() ?? '';
              final phone = user.phone?.toLowerCase() ?? '';

              return firstName.contains(searchLower) ||
                  lastName.contains(searchLower) ||
                  phone.contains(searchLower);
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<LoginData>(context).currentUserApp;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Passer une commande',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadUsers,
              tooltip: 'Recharger tous les clients',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chargement de tous les clients...',
                      style: TextStyle(color: AppColors.textDark),
                    ),
                  ],
                ),
              )
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: AppColors.primaryColor),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                      ),
                      onPressed: _loadUsers,
                      child: const Text(
                        'Réessayer le chargement',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour ${currentUser.firstName ?? 'Agent'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Information du nombre total de clients
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryGreen,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryColor),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: AppColors.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_allUsers.length} client(s) au total',
                                style: TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: AppColors.primaryColor,
                              size: 20,
                            ),
                            onPressed: _loadUsers,
                            tooltip: 'Actualiser',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sélection pour qui commander
                    const Text(
                      'Pour qui souhaitez-vous commander ?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    RadioListTile<String>(
                      title: const Text(
                        'Pour moi-même',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                      value: 'myself',
                      groupValue: _selectedOption,
                      activeColor: AppColors.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value!;
                          _selectedUser = null;
                        });
                      },
                    ),

                    RadioListTile<String>(
                      title: const Text(
                        'Pour un autre client',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                      value: 'other',
                      groupValue: _selectedOption,
                      activeColor: AppColors.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _selectedOption = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Section recherche de client
                    if (_selectedOption == 'other')
                      Expanded(child: _buildClientSearchSection())
                    else
                      const Spacer(),

                    // Bouton de confirmation
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed:
                            _getSelectedUser() != null
                                ? () {
                                  final selectedUser = _getSelectedUser();
                                  Navigator.of(context).pop(selectedUser);
                                }
                                : null,
                        child: const Text(
                          'Continuer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildClientSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rechercher un client',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Nom, prénom ou téléphone...',
            prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryColor),
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: AppColors.primaryColor),
                      onPressed: () {
                        _searchController.clear();
                        _filterUsers('');
                      },
                    )
                    : null,
          ),
          onChanged: _filterUsers,
        ),
        const SizedBox(height: 12),
        Text(
          '${_filteredUsers.length} client(s) trouvé(s) sur ${_allUsers.length}',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textGrey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildClientList()),
      ],
    );
  }

  Widget _buildClientList() {
    if (_filteredUsers.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.textGrey),
            const SizedBox(height: 16),
            const Text(
              'Aucun client trouvé',
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Recherche: "${_searchController.text}"',
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              onPressed: () {
                _searchController.clear();
                _filterUsers('');
              },
              child: const Text(
                'Réinitialiser la recherche',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textGrey),
            const SizedBox(height: 16),
            const Text(
              'Aucun client disponible',
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              onPressed: _loadUsers,
              child: const Text(
                'Recharger',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.borderGrey, width: 1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondaryGreen,
              child: Text(
                user.firstName?[0] ?? '?',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.phone ?? 'Aucun téléphone',
                  style: TextStyle(color: AppColors.textGrey),
                ),
                if (user.address != null)
                  Text(
                    user.address!,
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing:
                _selectedUser?.id == user.id
                    ? Icon(
                      Icons.check_circle,
                      color: AppColors.primaryColor,
                      size: 24,
                    )
                    : Icon(
                      Icons.radio_button_unchecked,
                      color: AppColors.borderGrey,
                      size: 24,
                    ),
            onTap: () {
              setState(() {
                _selectedUser = user;
              });
            },
          ),
        );
      },
    );
  }

  UserApp? _getSelectedUser() {
    if (_selectedOption == 'myself') {
      return Provider.of<LoginData>(context, listen: false).currentUserApp;
    } else {
      return _selectedUser;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
