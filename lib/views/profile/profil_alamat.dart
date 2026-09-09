import 'package:flutter/material.dart';
import 'package:fodos/constants/app_textstyle.dart';
import 'package:fodos/models/address_model.dart';
import 'package:fodos/service/preferencehandler.dart';

class ProfilAlamat extends StatefulWidget {
  const ProfilAlamat({super.key});

  @override
  State<ProfilAlamat> createState() => _ProfilAlamatState();
}

class _ProfilAlamatState extends State<ProfilAlamat> {
  List<AddressModel> _addresses = [];
  String _selectedAddressTitle = '';

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    setState(() {
      _addresses = PreferenceHandler.getSavedAddresses();
      _selectedAddressTitle = PreferenceHandler.getSelectedLocation();
    });
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'rumah':
        return Icons.home_rounded;
      case 'kantor':
        return Icons.business_rounded;
      case 'apartemen':
        return Icons.apartment_rounded;
      case 'kos':
        return Icons.hotel_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  void _setDefaultAddress(AddressModel item) async {
    final updatedList = _addresses.map((a) {
      return a.copyWith(isDefault: a.id == item.id);
    }).toList();

    await PreferenceHandler.saveAddresses(updatedList);
    await PreferenceHandler.setSelectedLocation(
      item.address,
      detail: item.detail.isNotEmpty ? item.detail : item.label,
    );

    _loadAddresses();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${item.label} dijadikan sebagai alamat utama"),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteAddress(String id) async {
    await PreferenceHandler.deleteSavedAddress(id);
    _loadAddresses();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Alamat berhasil dihapus"),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAddEditAddressSheet({AddressModel? editItem}) {
    final titleController = TextEditingController(text: editItem?.address ?? '');
    final detailController = TextEditingController(text: editItem?.detail ?? '');
    final nameController = TextEditingController(text: editItem?.receiverName ?? '');
    final phoneController = TextEditingController(text: editItem?.receiverPhone ?? '');
    String selectedLabel = editItem?.label ?? 'Rumah';
    final formKey = GlobalKey<FormState>();

    final List<String> availableLabels = [
      'Rumah',
      'Kantor',
      'Apartemen',
      'Kos',
      'Lainnya',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            editItem == null ? "Tambah Alamat Baru" : "Ubah Alamat",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, color: AppColors.textGrey),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Label Alamat",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: availableLabels.map((label) {
                          final isSelected = selectedLabel == label;
                          return ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedLabel = label;
                                });
                              }
                            },
                            selectedColor: AppColors.secondary,
                            backgroundColor: AppColors.background,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textDark,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            avatar: Icon(
                              _getIconForLabel(label),
                              size: 16,
                              color: isSelected ? Colors.white : AppColors.textGrey,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.secondary : AppColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Alamat / Jalan / Gedung",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: "Contoh: Jl. Senopati No. 12, Kebayoran Baru",
                          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Alamat tidak boleh kosong";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "Detail / Catatan Patokan",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: detailController,
                        decoration: InputDecoration(
                          hintText: "Contoh: Blok C No. 5, Samping Alfamart",
                          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                          prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textGrey, size: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final newAddr = AddressModel(
                              id: editItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                              label: selectedLabel,
                              address: titleController.text.trim(),
                              detail: detailController.text.trim(),
                              receiverName: nameController.text.trim(),
                              receiverPhone: phoneController.text.trim(),
                              isDefault: editItem?.isDefault ?? false,
                            );

                            if (editItem == null) {
                              await PreferenceHandler.addSavedAddress(newAddr);
                            } else {
                              await PreferenceHandler.updateSavedAddress(newAddr);
                            }

                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            _loadAddresses();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  editItem == null
                                      ? "Alamat baru berhasil ditambahkan!"
                                      : "Alamat berhasil diperbarui!",
                                ),
                                backgroundColor: AppColors.secondary,
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(
                            editItem == null ? "Simpan Alamat" : "Perbarui Alamat",
                            style: const TextStyle(
                              fontSize: 15,
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Alamat Tersimpan",
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: _addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 64,
                    color: AppColors.textGrey.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Belum ada alamat tersimpan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Tambahkan alamat untuk mempermudah pemesanan.",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final addr = _addresses[index];
                final isCurrentActive = _selectedAddressTitle == addr.address;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCurrentActive
                          ? AppColors.secondary
                          : AppColors.border.withValues(alpha: 0.7),
                      width: isCurrentActive ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCurrentActive
                                    ? AppColors.secondary.withValues(alpha: 0.12)
                                    : AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getIconForLabel(addr.label),
                                color: isCurrentActive
                                    ? AppColors.secondary
                                    : const Color(0xFF404941),
                                size: 20,
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      addr.label,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isCurrentActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "Aktif",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: AppColors.textGrey,
                                size: 20,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showAddEditAddressSheet(editItem: addr);
                                } else if (value == 'delete') {
                                  _deleteAddress(addr.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 18, color: AppColors.textDark),
                                      SizedBox(width: 8),
                                      Text("Ubah", style: TextStyle(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text("Hapus", style: TextStyle(fontSize: 13, color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          addr.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (addr.detail.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            addr.detail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.border),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isCurrentActive)
                              TextButton(
                                onPressed: () => _setDefaultAddress(addr),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  "Gunakan Lokasi Ini",
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEditAddressSheet(),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Tambah Alamat Baru",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}