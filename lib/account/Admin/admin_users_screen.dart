import 'package:flutter/material.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/services/user_service.dart';
import 'package:livraisonb2b/services/discount_service.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/constants/app_errors.dart';

class AdminUsersScreen extends StatefulWidget {
  static const String idScreen = "AdminUsersScreen";

  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  late Future<List<UserApp>> _usersFuture;
  final TextEditingController _searchController = TextEditingController();
  List<UserApp> _allUsers = [];
  List<UserApp> _filteredUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      _usersFuture = UserService.getUserCollection()
          .withConverter(
            fromFirestore: UserApp.fromFirestore,
            toFirestore: (UserApp userApp, _) => userApp.toFirestore(),
          )
          .get()
          .then((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

      final users = await _usersFuture;
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Erreur de chargement: ${e.toString()}');
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers =
          _allUsers.where((user) {
            final name =
                '${user.firstName ?? ''} ${user.lastName ?? ''}'.toLowerCase();
            final phone = user.phone?.toLowerCase() ?? '';
            return name.contains(query.toLowerCase()) ||
                phone.contains(query.toLowerCase());
          }).toList();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.primaryGreen),
    );
  }

  Widget _buildUserAvatar(UserApp user) {
    return CircleAvatar(
      backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
      backgroundImage:
          user.profileUrl != null ? NetworkImage(user.profileUrl!) : null,
      child:
          user.profileUrl == null
              ? Text(
                user.firstName?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(color: AppColors.primaryGreen),
              )
              : null,
    );
  }

  Widget _buildDiscountBadge(UserApp user) {
    if (user.personalDiscount == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '-${user.personalDiscount}%',
        style: TextStyle(
          color: Colors.green.shade800,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBonusBadge(UserApp user) {
    if (user.bonusThreshold == null) return const SizedBox();

    return Tooltip(
      message: 'Bonus: ${user.bonusRate}% après ${user.bonusThreshold} FCFA',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Bonus ${user.bonusRate}%',
          style: TextStyle(
            color: Colors.blue.shade800,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUserListTile(UserApp user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildUserAvatar(user),
        title: Text(
          '${user.firstName ?? 'N/A'} ${user.lastName ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.phone != null) Text(user.phone!),
            if (user.address != null)
              Text(user.address!, overflow: TextOverflow.ellipsis),
            Row(
              children: [
                _buildDiscountBadge(user),
                const SizedBox(width: 8),
                _buildBonusBadge(user),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder:
              (context) => [
                const PopupMenuItem(
                  value: 'discount',
                  child: Text('Gérer remise'),
                ),
                const PopupMenuItem(
                  value: 'bonus',
                  child: Text('Configurer bonus'),
                ),
                const PopupMenuItem(
                  value: 'history',
                  child: Text('Voir historique'),
                ),
              ],
          onSelected: (value) async {
            if (value == 'discount') {
              await _showDiscountDialog(user);
            } else if (value == 'bonus') {
              await _showBonusDialog(user);
            } else if (value == 'history') {
              _showDiscountHistory(user);
            }
          },
        ),
      ),
    );
  }

  Future<void> _showDiscountDialog(UserApp user) async {
    final discountController = TextEditingController(
      text: user.personalDiscount?.toStringAsFixed(0) ?? '0',
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remise pour ${user.firstName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Remise en %',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '0% = aucune remise\n100% = offre complète',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                onPressed: () async {
                  final discount =
                      double.tryParse(discountController.text) ?? 0;
                  if (discount >= 0 && discount <= 100) {
                    try {
                      await DiscountService.applyPersonalDiscount(
                        userId: user.id!,
                        discount: discount,
                        adminId: UserService.currentUserId,
                      );
                      _showSuccessSnackbar('Remise appliquée avec succès');
                      _loadUsers();
                    } catch (e) {
                      _showErrorSnackbar('Erreur: ${e.toString()}');
                    }
                    Navigator.pop(context);
                  } else {
                    _showErrorSnackbar(
                      'Veuillez entrer un pourcentage valide (0-100)',
                    );
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  Future<void> _showBonusDialog(UserApp user) async {
    final thresholdController = TextEditingController(
      text: user.bonusThreshold?.toStringAsFixed(0) ?? '',
    );
    final rateController = TextEditingController(
      text: user.bonusRate?.toStringAsFixed(0) ?? '',
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Programme bonus pour ${user.firstName}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Seuil minimum (FCFA)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rateController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Taux de bonus (%)',
                    suffixText: '%',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                ),
                onPressed: () async {
                  final threshold =
                      double.tryParse(thresholdController.text) ?? 0;
                  final rate = double.tryParse(rateController.text) ?? 0;

                  if (threshold > 0 && rate > 0) {
                    try {
                      await DiscountService.setupBonusProgram(
                        userId: user.id!,
                        threshold: threshold,
                        rate: rate,
                        adminId: UserService.currentUserId,
                      );
                      _showSuccessSnackbar('Bonus configuré avec succès');
                      _loadUsers();
                    } catch (e) {
                      _showErrorSnackbar('Erreur: ${e.toString()}');
                    }
                    Navigator.pop(context);
                  } else {
                    _showErrorSnackbar('Veuillez entrer des valeurs valides');
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  void _showDiscountHistory(UserApp user) {
    if (user.discountHistory == null || user.discountHistory!.isEmpty) {
      _showErrorSnackbar('Aucun historique de remise pour cet utilisateur');
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Historique remises - ${user.firstName}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: user.discountHistory!.length,
                itemBuilder: (context, index) {
                  final entry = user.discountHistory![index];
                  return ListTile(
                    title: Text(
                      entry['type'] == 'personal'
                          ? 'Remise: ${entry['value']}%'
                          : 'Bonus: ${entry['rate']}% > ${entry['threshold']} FCFA',
                    ),
                    subtitle: Text(
                      'Par admin #${entry['adminId']?.toString().substring(0, 6)}\n'
                      'Le ${DateTime.parse(entry['date']).toLocal()}',
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher utilisateur...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderGrey),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: _filterUsers,
      ),
    );
  }

  Widget _buildUserList() {
    if (_filteredUsers.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'Aucun utilisateur trouvé'
              : 'Aucun résultat pour "${_searchController.text}"',
          style: const TextStyle(color: AppColors.textGrey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _filteredUsers.length,
        itemBuilder:
            (context, index) => _buildUserListTile(_filteredUsers[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        backgroundColor: AppColors.primaryGreen,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchField(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildUserList(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
