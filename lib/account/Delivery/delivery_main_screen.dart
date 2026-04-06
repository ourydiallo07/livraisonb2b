import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:livraisonb2b/main_screen.dart';
import 'package:livraisonb2b/models/app_user.dart';
import 'package:livraisonb2b/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/models/order.dart';
import 'package:livraisonb2b/provider_data/order_provider.dart';
import 'package:livraisonb2b/provider_data/Login_data.dart';
import 'package:livraisonb2b/services/distance_calculator.dart';
import 'package:livraisonb2b/constants/order_status.dart';

class DeliveryMainScreen extends StatefulWidget {
  static const String idScreen = "DeliveryMainScreen";

  const DeliveryMainScreen({super.key});

  @override
  State<DeliveryMainScreen> createState() => _DeliveryMainScreenState();
}

class _DeliveryMainScreenState extends State<DeliveryMainScreen> {
  Position? _driverPosition;
  bool _isLoadingLocation = false;
  String _sortOption = 'distance'; // 'distance' ou 'date'
  bool _showOnlyWithCoordinates = true;

  @override
  void initState() {
    super.initState();
    _getDriverLocation();
  }

  Future<void> _getDriverLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Demander à l'utilisateur d'activer la localisation
        await Geolocator.openLocationSettings();
        throw Exception('Veuillez activer la localisation dans les paramètres');
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Rediriger vers les paramètres de l'appareil
        await Geolocator.openAppSettings();
        throw Exception(
          'Permission définitivement refusée. Activez-la dans les paramètres de l\'appareil.',
        );
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() => _driverPosition = position);

      print('✅ Position obtenue: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Erreur de localisation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Localisation: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _refreshLocation() async {
    await _getDriverLocation();
    if (_driverPosition != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position actualisée'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Méthode pour marquer une commande comme livrée
  Future<void> _markAsDelivered(String orderId) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      await orderProvider.markAsDelivered(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande marquée comme livrée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Ouvrir la navigation vers l'adresse
  void _openNavigation(Order order) async {
    if (order.deliveryLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune coordonnée GPS disponible pour cette adresse'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final latitude = order.deliveryLocation!.latitude;
    final longitude = order.deliveryLocation!.longitude;

    final url =
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$latitude,$longitude'
        '&travelmode=driving';

    // Utiliser url_launcher
    // try {
    //   if (await canLaunch(url)) {
    //     await launch(url);
    //   }
    // } catch (e) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Impossible d\'ouvrir Google Maps: $e'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ouvrir Google Maps avec les coordonnées'),
        backgroundColor: Colors.blue,
      ),
    );

    print('📌 Navigation vers: $latitude, $longitude');
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService.signOutAppUser();

      final loginData = Provider.of<LoginData>(context, listen: false);
      loginData.updateUserApp(UserApp());

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          MainScreen.idScreen,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final loginData = Provider.of<LoginData>(context);
    final userId = loginData.currentUserApp.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Livraisons'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          // Bouton de tri
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'distance',
                    child: Row(
                      children: [
                        Icon(
                          _sortOption == 'distance'
                              ? Icons.near_me
                              : Icons.near_me_outlined,
                          size: 20,
                          color:
                              _driverPosition != null
                                  ? AppColors.primaryColor
                                  : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trier par distance',
                          style: TextStyle(
                            color:
                                _driverPosition != null
                                    ? Colors.black
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'date',
                    child: Row(
                      children: [
                        Icon(
                          _sortOption == 'date'
                              ? Icons.access_time
                              : Icons.access_time_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Trier par date'),
                      ],
                    ),
                  ),
                ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.sort, color: Colors.white),
            ),
          ),
          // Filtre des commandes avec coordonnées
          IconButton(
            icon: Icon(
              _showOnlyWithCoordinates ? Icons.location_on : Icons.location_off,
              color: _showOnlyWithCoordinates ? Colors.white : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _showOnlyWithCoordinates = !_showOnlyWithCoordinates;
              });
            },
            tooltip:
                _showOnlyWithCoordinates
                    ? 'Afficher toutes les commandes'
                    : 'Afficher seulement les commandes avec localisation',
          ),
          // Bouton de rafraîchissement
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshLocation,
            tooltip: 'Actualiser la position',
          ),

          // Option 3: Déconnexion
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _signOut(context);
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec position
          _buildLocationHeader(),

          // Liste des commandes
          Expanded(
            child:
                userId != null
                    ? _buildOrdersList(orderProvider, userId)
                    : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Veuillez vous connecter',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshLocation,
        backgroundColor: AppColors.primaryColor,
        child: Icon(
          _isLoadingLocation ? Icons.gps_fixed : Icons.gps_not_fixed,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _driverPosition != null ? Colors.green[50] : Colors.orange[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: _driverPosition != null ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverPosition != null
                      ? 'Position active'
                      : 'Localisation nécessaire',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _driverPosition != null
                      ? '${_driverPosition!.latitude.toStringAsFixed(5)}, ${_driverPosition!.longitude.toStringAsFixed(5)}'
                      : 'Activez la localisation pour trier par distance',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (_driverPosition != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Tri: ${_sortOption == 'distance' ? 'Distance (plus proche d\'abord)' : 'Date (plus récente d\'abord)'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoadingLocation)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(OrderProvider orderProvider, String userId) {
    return StreamBuilder<List<Order>>(
      stream:
          _driverPosition != null && _sortOption == 'distance'
              ? orderProvider.getOrdersForDeliveryManWithDistance(
                userId,
                _driverPosition!,
              )
              : orderProvider.getOrdersForDeliveryMan(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];

        // Filtrer les commandes sans coordonnées si demandé
        List<Order> filteredOrders = orders;
        if (_showOnlyWithCoordinates) {
          filteredOrders =
              orders.where((order) => order.deliveryLocation != null).toList();
        }

        if (filteredOrders.isEmpty) {
          return _buildEmptyState(orders.isEmpty);
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              return _buildOrderCard(order);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    final hasCoordinates = order.deliveryLocation != null;
    final distance = order.distanceInMeters;
    final weight = order.getTotalWeight();
    final isDelivered = order.status == OrderStatus.delivered;

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec numéro de commande et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Commande #${order.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                // Distance ou indicateur de localisation
                if (distance != null)
                  Chip(
                    label: Text(DistanceCalculator.formatDistance(distance)),
                    backgroundColor: _getDistanceColor(distance),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                else if (hasCoordinates)
                  Chip(
                    label: const Text('GPS'),
                    backgroundColor: Colors.blue,
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  )
                else
                  Chip(
                    label: const Text('Sans GPS'),
                    backgroundColor: Colors.grey,
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations client
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                  child: Text(
                    order.userfirstName.isNotEmpty
                        ? order.userfirstName[0]
                        : '?',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.userfirstName} ${order.userlastName}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        order.userphone,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Adresse de livraison
            if (order.deliveryAddress != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: hasCoordinates ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.deliveryAddress!,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!hasCoordinates)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '(Adresse sans coordonnées GPS)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // Détails de la commande
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.items.length} article${order.items.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${weight.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${order.total.toStringAsFixed(2)} FCFA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    _buildStatusBadge(order.status),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showOrderDetails(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.remove_red_eye,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Détails',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasCoordinates && !isDelivered)
                  ElevatedButton.icon(
                    onPressed: () => _openNavigation(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.directions,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Itinéraire',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(width: 8),
                if (!isDelivered)
                  ElevatedButton.icon(
                    onPressed: () => _markAsDelivered(order.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Livrée',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getDistanceColor(double distanceInMeters) {
    if (distanceInMeters < 1000) return Colors.green;
    if (distanceInMeters < 3000) return Colors.lightGreen;
    if (distanceInMeters < 8000) return Colors.orange;
    if (distanceInMeters < 15000) return Colors.orangeAccent;
    return Colors.red;
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final text = OrderStatus.getFrenchTranslation(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.lightBlue;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState(bool noOrdersAtAll) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            noOrdersAtAll ? Icons.local_shipping : Icons.location_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            noOrdersAtAll
                ? 'Aucune livraison disponible'
                : 'Aucune commande avec localisation GPS',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (!noOrdersAtAll && _showOnlyWithCoordinates)
            Text(
              'Désactivez le filtre GPS pour voir toutes les commandes',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          if (_driverPosition == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: _getDriverLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.gps_fixed, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Activer la localisation',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!noOrdersAtAll && _showOnlyWithCoordinates)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showOnlyWithCoordinates = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt_off, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Voir toutes les commandes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Commande #${order.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Informations client
                  const Text(
                    'Client',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      child: Text(
                        order.userfirstName.isNotEmpty
                            ? order.userfirstName[0]
                            : '?',
                        style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text('${order.userfirstName} ${order.userlastName}'),
                    subtitle: Text(order.userphone),
                  ),

                  // Adresse
                  if (order.deliveryAddress != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Adresse de livraison',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Icon(
                        Icons.location_on,
                        color:
                            order.deliveryLocation != null
                                ? Colors.green
                                : Colors.orange,
                      ),
                      title: const Text('Adresse'),
                      subtitle: Text(order.deliveryAddress!),
                    ),
                  ],

                  // Distance
                  if (order.distanceInMeters != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Distance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Icon(
                        Icons.near_me,
                        color: _getDistanceColor(order.distanceInMeters!),
                      ),
                      title: const Text('Distance estimée'),
                      subtitle: Text(
                        DistanceCalculator.formatDistance(
                          order.distanceInMeters,
                        ),
                      ),
                      trailing:
                          order.deliveryLocation != null
                              ? ElevatedButton(
                                onPressed: () => _openNavigation(order),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text(
                                  'Itinéraire',
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                              : null,
                    ),
                  ],

                  // Articles
                  const SizedBox(height: 16),
                  const Text(
                    'Articles commandés',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items
                      .map(
                        (item) => ListTile(
                          leading:
                              item.imageUrl != null
                                  ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      item.imageUrl!,
                                    ),
                                  )
                                  : CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    child: Icon(
                                      Icons.shopping_basket,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.quantity} x ${item.price} FCFA',
                          ),
                          trailing: Text(
                            '${(item.quantity * item.price).toStringAsFixed(2)} FCFA',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                      .toList(),

                  // Total
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${order.total.toStringAsFixed(2)} FCFA',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            '${order.getTotalWeight().toStringAsFixed(1)} kg',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Bouton de fermeture
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Fermer',
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
          ),
    );
  }
}
