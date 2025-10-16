import 'package:flutter/material.dart';
import 'package:bbd_limited/models/invoice_options.dart';
import 'package:bbd_limited/components/text_input.dart';
import 'package:bbd_limited/components/custom_dropdown.dart';

class InvoiceOptionsConfig extends StatefulWidget {
  final InvoiceOptions options;
  final ValueChanged<InvoiceOptions> onOptionsChanged;
  final String currencySymbol;

  const InvoiceOptionsConfig({
    Key? key,
    required this.options,
    required this.onOptionsChanged,
    this.currencySymbol = '¥',
  }) : super(key: key);

  @override
  State<InvoiceOptionsConfig> createState() => _InvoiceOptionsConfigState();
}

class _InvoiceOptionsConfigState extends State<InvoiceOptionsConfig> {
  late InvoiceOptions _options;
  final _formKey = GlobalKey<FormState>();
  final _lineMarginController = TextEditingController();
  final _globalMarginController = TextEditingController();
  final _discountController = TextEditingController();
  final _storageFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _options = widget.options;
    _initializeControllers();
    _addControllersListeners();
  }

  @override
  void didUpdateWidget(InvoiceOptionsConfig oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _options = widget.options;
      _updateControllersFromOptions();
    }
  }

  void _initializeControllers() {
    _lineMarginController.text = _options.lineMarginValue?.toString() ?? '10';
    _globalMarginController.text =
        _options.globalMarginValue?.toString() ?? '15';
    _discountController.text = _options.discountValue?.toString() ?? '5';
    _storageFeeController.text = _options.storageFeeAmount?.toString() ?? '25';
  }

  void _updateControllersFromOptions() {
    _lineMarginController.text = _options.lineMarginValue?.toString() ?? '10';
    _globalMarginController.text =
        _options.globalMarginValue?.toString() ?? '15';
    _discountController.text = _options.discountValue?.toString() ?? '5';
    _storageFeeController.text = _options.storageFeeAmount?.toString() ?? '25';
  }

  void _addControllersListeners() {
    // Suppression des listeners automatiques pour éviter les mises à jour pendant la frappe
  }

  @override
  void dispose() {
    _lineMarginController.dispose();
    _globalMarginController.dispose();
    _discountController.dispose();
    _storageFeeController.dispose();
    super.dispose();
  }

  void _updateOptions(InvoiceOptions newOptions) {
    setState(() {
      _options = newOptions;
    });
    _updateControllersFromOptions();
    widget.onOptionsChanged(newOptions);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre principal
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E49),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Configuration des options de facturation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personnalisez vos factures avec des marges, remises et frais',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Design conditionnel : Mobile vs Tablet
            if (isTablet) ...[
              // Design tablette (actuel)
              _buildTabletDesign(),
            ] else ...[
              // Design mobile (nouveau)
              _buildMobileDesign(),
            ],

            if (_hasActiveOptions) ...[
              const SizedBox(height: 24),
              _buildSummaryCard(),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasActiveOptions {
    return _options.enableLineMargin ||
        _options.enableGlobalMargin ||
        _options.enableDiscount ||
        _options.enableStorageFees;
  }

  /// Design pour tablettes - garde le design actuel
  Widget _buildTabletDesign() {
    return Column(
      children: [
        // Section Marges
        _buildSectionCard(
          title: 'Marges',
          icon: Icons.trending_up,
          children: [
            // Marge par ligne
            _buildOptionTile(
              title: 'Marge par ligne',
              subtitle: 'Ajouter une marge sur chaque ligne',
              value: _options.enableLineMargin,
              onChanged: (value) {
                _updateOptions(_options.copyWith(
                  enableLineMargin: value ?? false,
                  lineMarginValue: value == true ? 10.0 : null,
                ));
              },
              children: [
                if (_options.enableLineMargin) ...[
                  const SizedBox(height: 16),
                  _buildResponsiveRow([
                    DropDownCustom<MarginType>(
                      selectedItem: _options.lineMarginType,
                      items: MarginType.values.toList(),
                      itemToString: (type) => type == MarginType.percentage
                          ? 'Pourcentage'
                          : 'Montant fixe',
                      onChanged: (type) {
                        if (type != null) {
                          _updateOptions(_options.copyWith(
                            lineMarginType: type,
                            lineMarginValue:
                                type == MarginType.percentage ? 10.0 : 5.0,
                          ));
                        }
                      },
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildTextField(
                          controller: _lineMarginController,
                          label:
                              _options.lineMarginType == MarginType.percentage
                                  ? 'Pourcentage (%)'
                                  : 'Montant (${widget.currencySymbol})',
                          icon: _options.lineMarginType == MarginType.percentage
                              ? Icons.percent
                              : Icons.attach_money,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final amount = double.tryParse(value);
                            if (amount != null &&
                                amount != _options.lineMarginValue) {
                              _updateOptions(
                                  _options.copyWith(lineMarginValue: amount));
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Requis';
                            final amount = double.tryParse(value);
                            if (amount == null || amount < 0)
                              return 'Doit être positif';
                            if (_options.lineMarginType ==
                                    MarginType.percentage &&
                                amount > 100) {
                              return 'Doit être ≤ 100%';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ]),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Marge globale
            _buildOptionTile(
              title: 'Marge globale',
              subtitle: 'Ajouter une marge sur le total',
              value: _options.enableGlobalMargin,
              onChanged: (value) {
                _updateOptions(_options.copyWith(
                  enableGlobalMargin: value ?? false,
                  globalMarginValue: value == true ? 15.0 : null,
                ));
              },
              children: [
                if (_options.enableGlobalMargin) ...[
                  const SizedBox(height: 16),
                  _buildResponsiveRow([
                    DropDownCustom<MarginType>(
                      selectedItem: _options.globalMarginType,
                      items: MarginType.values.toList(),
                      itemToString: (type) => type == MarginType.percentage
                          ? 'Pourcentage'
                          : 'Montant fixe',
                      onChanged: (type) {
                        if (type != null) {
                          _updateOptions(_options.copyWith(
                            globalMarginType: type,
                            globalMarginValue:
                                type == MarginType.percentage ? 15.0 : 10.0,
                          ));
                        }
                      },
                    ),
                    buildTextField(
                      controller: _globalMarginController,
                      label: _options.globalMarginType == MarginType.percentage
                          ? 'Pourcentage (%)'
                          : 'Montant (${widget.currencySymbol})',
                      icon: _options.globalMarginType == MarginType.percentage
                          ? Icons.percent
                          : Icons.attach_money,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final amount = double.tryParse(value);
                        if (amount != null &&
                            amount != _options.globalMarginValue) {
                          _updateOptions(
                              _options.copyWith(globalMarginValue: amount));
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requis';
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0)
                          return 'Doit être positif';
                        if (_options.globalMarginType ==
                                MarginType.percentage &&
                            amount > 100) {
                          return 'Doit être ≤ 100%';
                        }
                        return null;
                      },
                    ),
                  ]),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section Remises
        _buildSectionCard(
          title: 'Remises',
          icon: Icons.discount,
          children: [
            _buildOptionTile(
              title: 'Remise',
              subtitle: 'Appliquer une remise sur le total',
              value: _options.enableDiscount,
              onChanged: (value) {
                _updateOptions(_options.copyWith(
                  enableDiscount: value ?? false,
                  discountValue: value == true ? 5.0 : null,
                ));
              },
              children: [
                if (_options.enableDiscount) ...[
                  const SizedBox(height: 16),
                  _buildResponsiveRow([
                    DropDownCustom<DiscountType>(
                      selectedItem: _options.discountType,
                      items: DiscountType.values.toList(),
                      itemToString: (type) => type == DiscountType.percentage
                          ? 'Pourcentage'
                          : 'Montant fixe',
                      onChanged: (type) {
                        if (type != null) {
                          _updateOptions(_options.copyWith(
                            discountType: type,
                            discountValue:
                                type == DiscountType.percentage ? 5.0 : 10.0,
                          ));
                        }
                      },
                    ),
                    buildTextField(
                      controller: _discountController,
                      label: _options.discountType == DiscountType.percentage
                          ? 'Pourcentage de remise (%)'
                          : 'Montant de remise (${widget.currencySymbol})',
                      icon: Icons.discount,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requis';
                        final discount = double.tryParse(value);
                        if (discount == null || discount < 0)
                          return 'Doit être positif';
                        if (_options.discountType == DiscountType.percentage &&
                            discount > 100) {
                          return 'Doit être ≤ 100%';
                        }
                        return null;
                      },
                    ),
                  ]),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section Frais d'entreposage
        _buildSectionCard(
          title: 'Frais d\'entreposage',
          icon: Icons.warehouse,
          children: [
            _buildOptionTile(
              title: 'Frais d\'entreposage',
              subtitle: 'Ajouter des frais d\'entreposage',
              value: _options.enableStorageFees,
              onChanged: (value) {
                _updateOptions(_options.copyWith(
                  enableStorageFees: value ?? false,
                  storageFeeAmount: value == true ? 25.0 : null,
                ));
              },
              children: [
                if (_options.enableStorageFees) ...[
                  const SizedBox(height: 16),
                  _buildResponsiveRow([
                    DropDownCustom<StorageFeeType>(
                      selectedItem: _options.storageFeeType,
                      items: StorageFeeType.values.toList(),
                      itemToString: (type) => type == StorageFeeType.percentage
                          ? 'Pourcentage'
                          : 'Montant fixe',
                      onChanged: (type) {
                        if (type != null) {
                          _updateOptions(_options.copyWith(
                            storageFeeType: type,
                            storageFeeAmount:
                                type == StorageFeeType.percentage ? 2.0 : 25.0,
                          ));
                          if (type == StorageFeeType.percentage) {
                            _storageFeeController.text = '2';
                          } else {
                            _storageFeeController.text = '25';
                          }
                        }
                      },
                    ),
                    buildTextField(
                      controller: _storageFeeController,
                      label:
                          _options.storageFeeType == StorageFeeType.percentage
                              ? 'Pourcentage (%)'
                              : 'Montant (${widget.currencySymbol})',
                      icon: Icons.warehouse,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final amount = double.tryParse(value);
                        if (amount != null &&
                            amount != _options.storageFeeAmount) {
                          _updateOptions(
                              _options.copyWith(storageFeeAmount: amount));
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Requis';
                        final amount = double.tryParse(value);
                        if (amount == null || amount < 0)
                          return 'Doit être positif';
                        if (_options.storageFeeType ==
                                StorageFeeType.percentage &&
                            amount > 100) {
                          return 'Doit être ≤ 100%';
                        }
                        return null;
                      },
                    ),
                  ]),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Design pour mobile - complètement différent
  Widget _buildMobileDesign() {
    return Column(
      children: [
        // Cartes d'options en mode mobile
        _buildMobileOptionCard(
          title: 'Marge par ligne',
          subtitle: 'Ajouter une marge sur chaque ligne',
          icon: Icons.trending_up,
          color: Colors.blue,
          isEnabled: _options.enableLineMargin,
          onToggle: (value) {
            _updateOptions(_options.copyWith(
              enableLineMargin: value,
              lineMarginValue: value ? 10.0 : null,
            ));
          },
          child:
              _options.enableLineMargin ? _buildLineMarginMobileConfig() : null,
        ),

        const SizedBox(height: 16),

        _buildMobileOptionCard(
          title: 'Marge globale',
          subtitle: 'Ajouter une marge sur le total',
          icon: Icons.trending_up,
          color: Colors.green,
          isEnabled: _options.enableGlobalMargin,
          onToggle: (value) {
            _updateOptions(_options.copyWith(
              enableGlobalMargin: value,
              globalMarginValue: value ? 15.0 : null,
            ));
          },
          child: _options.enableGlobalMargin
              ? _buildGlobalMarginMobileConfig()
              : null,
        ),

        const SizedBox(height: 16),

        _buildMobileOptionCard(
          title: 'Remise',
          subtitle: 'Appliquer une remise sur le total',
          icon: Icons.discount,
          color: Colors.orange,
          isEnabled: _options.enableDiscount,
          onToggle: (value) {
            _updateOptions(_options.copyWith(
              enableDiscount: value,
              discountValue: value ? 5.0 : null,
            ));
          },
          child: _options.enableDiscount ? _buildDiscountMobileConfig() : null,
        ),

        const SizedBox(height: 16),

        _buildMobileOptionCard(
          title: 'Frais d\'entreposage',
          subtitle: 'Ajouter des frais d\'entreposage',
          icon: Icons.warehouse,
          color: Colors.purple,
          isEnabled: _options.enableStorageFees,
          onToggle: (value) {
            _updateOptions(_options.copyWith(
              enableStorageFees: value,
              storageFeeAmount: value ? 25.0 : null,
            ));
          },
          child: _options.enableStorageFees
              ? _buildStorageFeeMobileConfig()
              : null,
        ),
      ],
    );
  }

  /// Carte d'option pour mobile
  Widget _buildMobileOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required Function(bool) onToggle,
    Widget? child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? color : Colors.grey[300]!,
          width: isEnabled ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la carte
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isEnabled ? color : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isEnabled ? color : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isEnabled
                              ? color.withOpacity(0.8)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: onToggle,
                  activeColor: color,
                ),
              ],
            ),
          ),

          // Contenu de configuration
          if (child != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  /// Configuration marge par ligne pour mobile
  Widget _buildLineMarginMobileConfig() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropDownCustom<MarginType>(
          selectedItem: _options.lineMarginType,
          items: MarginType.values.toList(),
          itemToString: (type) =>
              type == MarginType.percentage ? 'Pourcentage' : 'Montant fixe',
          onChanged: (type) {
            if (type != null) {
              _updateOptions(_options.copyWith(
                lineMarginType: type,
                lineMarginValue: type == MarginType.percentage ? 10.0 : 5.0,
              ));
            }
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _lineMarginController,
          label: _options.lineMarginType == MarginType.percentage
              ? 'Pourcentage (%)'
              : 'Montant (${widget.currencySymbol})',
          icon: _options.lineMarginType == MarginType.percentage
              ? Icons.percent
              : Icons.attach_money,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final amount = double.tryParse(value);
            if (amount != null && amount != _options.lineMarginValue) {
              _updateOptions(_options.copyWith(lineMarginValue: amount));
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            final amount = double.tryParse(value);
            if (amount == null || amount < 0) return 'Doit être positif';
            if (_options.lineMarginType == MarginType.percentage &&
                amount > 100) {
              return 'Doit être ≤ 100%';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Configuration marge globale pour mobile
  Widget _buildGlobalMarginMobileConfig() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropDownCustom<MarginType>(
          selectedItem: _options.globalMarginType,
          items: MarginType.values.toList(),
          itemToString: (type) =>
              type == MarginType.percentage ? 'Pourcentage' : 'Montant fixe',
          onChanged: (type) {
            if (type != null) {
              _updateOptions(_options.copyWith(
                globalMarginType: type,
                globalMarginValue: type == MarginType.percentage ? 15.0 : 10.0,
              ));
            }
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _globalMarginController,
          label: _options.globalMarginType == MarginType.percentage
              ? 'Pourcentage (%)'
              : 'Montant (${widget.currencySymbol})',
          icon: _options.globalMarginType == MarginType.percentage
              ? Icons.percent
              : Icons.attach_money,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final amount = double.tryParse(value);
            if (amount != null && amount != _options.globalMarginValue) {
              _updateOptions(_options.copyWith(globalMarginValue: amount));
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            final amount = double.tryParse(value);
            if (amount == null || amount < 0) return 'Doit être positif';
            if (_options.globalMarginType == MarginType.percentage &&
                amount > 100) {
              return 'Doit être ≤ 100%';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Configuration remise pour mobile
  Widget _buildDiscountMobileConfig() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropDownCustom<DiscountType>(
          selectedItem: _options.discountType,
          items: DiscountType.values.toList(),
          itemToString: (type) =>
              type == DiscountType.percentage ? 'Pourcentage' : 'Montant fixe',
          onChanged: (type) {
            if (type != null) {
              _updateOptions(_options.copyWith(
                discountType: type,
                discountValue: type == DiscountType.percentage ? 5.0 : 10.0,
              ));
            }
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _discountController,
          label: _options.discountType == DiscountType.percentage
              ? 'Pourcentage de remise (%)'
              : 'Montant de remise (${widget.currencySymbol})',
          icon: Icons.discount,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            final discount = double.tryParse(value);
            if (discount == null || discount < 0) return 'Doit être positif';
            if (_options.discountType == DiscountType.percentage &&
                discount > 100) {
              return 'Doit être ≤ 100%';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Configuration frais d'entreposage pour mobile
  Widget _buildStorageFeeMobileConfig() {
    return Column(
      children: [
        const SizedBox(height: 16),
        DropDownCustom<StorageFeeType>(
          selectedItem: _options.storageFeeType,
          items: StorageFeeType.values.toList(),
          itemToString: (type) => type == StorageFeeType.percentage
              ? 'Pourcentage'
              : 'Montant fixe',
          onChanged: (type) {
            if (type != null) {
              _updateOptions(_options.copyWith(
                storageFeeType: type,
                storageFeeAmount:
                    type == StorageFeeType.percentage ? 2.0 : 25.0,
              ));
              if (type == StorageFeeType.percentage) {
                _storageFeeController.text = '2';
              } else {
                _storageFeeController.text = '25';
              }
            }
          },
        ),
        const SizedBox(height: 16),
        buildTextField(
          controller: _storageFeeController,
          label: _options.storageFeeType == StorageFeeType.percentage
              ? 'Pourcentage (%)'
              : 'Montant (${widget.currencySymbol})',
          icon: Icons.warehouse,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final amount = double.tryParse(value);
            if (amount != null && amount != _options.storageFeeAmount) {
              _updateOptions(_options.copyWith(storageFeeAmount: amount));
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requis';
            final amount = double.tryParse(value);
            if (amount == null || amount < 0) return 'Doit être positif';
            if (_options.storageFeeType == StorageFeeType.percentage &&
                amount > 100) {
              return 'Doit être ≤ 100%';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E49).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF1A1E49),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1E49),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? Colors.blue[200]! : Colors.grey[200]!,
          width: value ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF1A1E49),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: value
                              ? const Color(0xFF1A1E49)
                              : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: value ? Colors.blue[600] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (value) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green[600], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Actif',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (value) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Configuration',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...children,
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[50]!,
            Colors.blue[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Résumé des options appliquées',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSummaryRow(
                'Marge par ligne',
                _options.enableLineMargin,
                _options.lineMarginValue != null
                    ? '${_options.lineMarginValue}${_options.lineMarginType == MarginType.percentage ? '%' : widget.currencySymbol}'
                    : null),
            _buildSummaryRow(
                'Marge globale',
                _options.enableGlobalMargin,
                _options.globalMarginValue != null
                    ? '${_options.globalMarginValue}${_options.globalMarginType == MarginType.percentage ? '%' : widget.currencySymbol}'
                    : null),
            _buildSummaryRow(
                'Remise',
                _options.enableDiscount,
                _options.discountValue != null
                    ? (_options.discountType == DiscountType.percentage
                        ? '${_options.discountValue}%'
                        : '${widget.currencySymbol}${_options.discountValue}')
                    : null),
            _buildSummaryRow(
                'Frais d\'entreposage',
                _options.enableStorageFees,
                _options.storageFeeAmount != null
                    ? (_options.storageFeeType == StorageFeeType.percentage
                        ? '${_options.storageFeeAmount}%'
                        : '${widget.currencySymbol}${_options.storageFeeAmount}')
                    : null),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, bool isActive, String? value) {
    if (!isActive) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a responsive row that stacks vertically on mobile and horizontally on tablet
  Widget _buildResponsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isTablet = screenWidth > 768;

        if (isTablet) {
          // Tablet layout: horizontal row
          return Row(
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 16),
              Expanded(child: children[1]),
            ],
          );
        } else {
          // Mobile layout: vertical column
          return Column(
            children: [
              children[0],
              const SizedBox(height: 16),
              children[1],
            ],
          );
        }
      },
    );
  }
}
