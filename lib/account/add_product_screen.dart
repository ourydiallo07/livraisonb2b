import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:livraisonb2b/constants/theme.dart';
import 'package:livraisonb2b/provider_data/app_data.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../provider_data/product_provider.dart';
import '../../global_utils/utils.dart';

class AddProductScreen extends StatefulWidget {
  static const String idScreen = "addProduct";
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _sacSizeController = TextEditingController(); // Added
  File? _selectedImage;
  String _selectedUnit = 'kg'; // Added: Default unit is 'kg'

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final newProduct = Product(
      id: DateTime.now().toString(),
      name: _nameController.text,
      description: _descController.text,
      price: double.parse(_priceController.text),
      imageUrl: '',
      unit: _selectedUnit,
      sacSize:
          _selectedUnit == 'sac' && _sacSizeController.text.isNotEmpty
              ? int.parse(_sacSizeController.text)
              : null,
    );

    try {
      Utils.showLoadingDialog(context);

      final appData = Provider.of<AppData>(context, listen: false);

      await Provider.of<ProductProvider>(
        context,
        listen: false,
      ).addProduct(newProduct, _selectedImage, appData);

      if (!mounted) return;

      Navigator.pop(context); // Close loading dialog
      displayMessage("Produit ajouté avec succès!", context, false);

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context); // Close the add product screen
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog on error
      displayMessage("Erreur: ${e.toString()}", context, true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _sacSizeController.dispose(); // Added
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouveau Produit"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  child:
                      _selectedImage != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                          : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ajouter une image',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                ),
              ),
              const SizedBox(height: 30),

              // Product Name
              Text(
                'Nom du produit',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Entrez le nom du produit',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator:
                    (value) => value!.isEmpty ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 20),

              // Unit Selection
              Text(
                'Unité',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items:
                    ['kg', 'sac'].map((String unit) {
                      return DropdownMenuItem<String>(
                        value: unit,
                        child: Text(unit.toUpperCase()),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value!;
                  });
                },
                validator:
                    (value) => value == null ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 20),

              if (_selectedUnit == 'kg') ...[
                Text(
                  'Poids en (kg)',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sacSizeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Entrez le poids en kG (ex. 1 )',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixText: 'kg',
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? "Champ obligatoire pour les produits en kg"
                              : null,
                ),
                const SizedBox(height: 20),
              ],

              // Sac Size (visible only if unit is 'sac')
              if (_selectedUnit == 'sac') ...[
                Text(
                  'Taille du sac (kg)',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sacSizeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Entrez la taille du sac en kg (ex. 25)',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? "Champ obligatoire pour les sacs"
                              : null,
                ),
                const SizedBox(height: 20),
              ],

              // Price
              Text(
                'Prix (GNF)',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Entrez le prix en GNF',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixText: 'GNF ',
                ),
                validator:
                    (value) => value!.isEmpty ? "Champ obligatoire" : null,
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                'Description (optionnel)',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Décrivez le produit...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Enregistrer le produit",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
