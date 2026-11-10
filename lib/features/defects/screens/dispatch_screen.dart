import 'package:burgess_go/features/defects/controllers/dispatch_controller.dart';
import 'package:burgess_go/features/trade_contact/controllers/trade_contact_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:burgess_go/features/trade_contact/models/trade_contact.dart';
import 'package:burgess_go/features/defects/states/dispatch_state.dart';
import 'package:burgess_go/core/models/inspection/submission_detail.dart';

class DispatchScreen extends ConsumerStatefulWidget {
  final List<SubmissionDetail> selectedDetails;
  final int inspectionId;

  const DispatchScreen({
    super.key,
    required this.selectedDetails,
    required this.inspectionId,
  });

  @override
  ConsumerState<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends ConsumerState<DispatchScreen> {
  @override
  void initState() {
    super.initState();
    // Safely inject the items into the state the moment the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dispatchControllerProvider.notifier)
          .init(widget.selectedDetails);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dispatchControllerProvider);
    final controller = ref.read(dispatchControllerProvider.notifier);

    final contactsAsync = ref.watch(tradeContactControllerProvider);
    final allContacts = contactsAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dispatch Punch List"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          if (state.selectedTrade != null && state.itemsToDispatch.isNotEmpty)
            TextButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => _showDeliveryMethodSheet(
                      context,
                      ref,
                      state,
                      controller,
                    ),
              child: const Text(
                "SEND",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTradeSelector(context, ref, state, allContacts),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: state.itemsToDispatch.length,
              itemBuilder: (context, index) {
                final item = state.itemsToDispatch[index];
                return _buildDispatchTile(context, item, controller);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showAddCustomItemDialog(context, controller),
              icon: const Icon(Icons.add),
              label: const Text("ADD CUSTOM ITEM"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeSelector(
    BuildContext context,
    WidgetRef ref,
    DispatchState state,
    List<TradeContact> contacts,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SEND TO:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          state.selectedTrade == null
              ? OutlinedButton(
                  onPressed: () => _showTradeSearch(
                    context,
                    contacts,
                    (c) => ref
                        .read(dispatchControllerProvider.notifier)
                        .selectTrade(c),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_search),
                      SizedBox(width: 8),
                      Text("Search Rolodex..."),
                    ],
                  ),
                )
              : ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(state.selectedTrade!.name[0]),
                  ),
                  title: Text(state.selectedTrade!.name),
                  subtitle: Text(state.selectedTrade!.trade),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => ref
                        .read(dispatchControllerProvider.notifier)
                        .selectTrade(null),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildDispatchTile(
    BuildContext context,
    dynamic item,
    DispatchController controller,
  ) {
    return ListTile(
      title: Text(item.description),
      subtitle: item.isCustom
          ? const Text(
              "Custom Item",
              style: TextStyle(color: Colors.orange, fontSize: 11),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Req Photo", style: TextStyle(fontSize: 12)),
          Switch(
            value: item.requirePhoto,
            onChanged: (_) => controller.togglePhotoRequirement(item.defectId),
            activeColor: Colors.blue[900],
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => controller.removeItem(item.defectId),
          ),
        ],
      ),
    );
  }

  void _showTradeSearch(
    BuildContext context,
    List<TradeContact> contacts,
    Function(TradeContact) onSelect,
  ) {
    String query = "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final lowerQuery = query.toLowerCase();
          final filtered = contacts.where((c) {
            return c.name.toLowerCase().contains(lowerQuery) ||
                c.trade.toLowerCase().contains(lowerQuery) ||
                (c.email?.toLowerCase().contains(lowerQuery) ?? false) ||
                (c.phone?.contains(lowerQuery) ?? false);
          }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: "Search Contacts",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => query = ""),
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => query = val),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            "No contacts found in rolodex.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) => ListTile(
                            leading: CircleAvatar(
                              child: Text(filtered[i].name[0]),
                            ),
                            title: Text(filtered[i].name),
                            subtitle: Text(filtered[i].trade),
                            trailing: Text(
                              filtered[i].phone ?? "",
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              onSelect(filtered[i]);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddCustomItemDialog(
    BuildContext context,
    DispatchController controller,
  ) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Custom Item"),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: "Enter task description...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                controller.addCustomItem(textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // --- NEW: Delivery Method Bottom Sheet ---
  void _showDeliveryMethodSheet(
    BuildContext context,
    WidgetRef ref,
    DispatchState state,
    DispatchController controller,
  ) {
    if (state.selectedTrade == null) return;
    final trade = state.selectedTrade!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Send to ${trade.name}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ),
              const Divider(height: 1),

              if (trade.phone != null && trade.phone!.isNotEmpty)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Icon(Icons.sms, color: Colors.green[800]),
                  ),
                  title: const Text("Send Text Message"),
                  subtitle: Text(trade.phone!),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    controller.sendToTrade(
                      widget.inspectionId,
                      context,
                      method: 'sms',
                    );
                  },
                ),

              if (trade.email != null && trade.email!.isNotEmpty)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.email, color: Colors.blue[800]),
                  ),
                  title: const Text("Send Email"),
                  subtitle: Text(trade.email!),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    controller.sendToTrade(
                      widget.inspectionId,
                      context,
                      method: 'email',
                    );
                  },
                ),

              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.copy, color: Colors.grey[800]),
                ),
                title: const Text("Just Copy Link"),
                subtitle: const Text("I'll send it myself manually"),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  controller.sendToTrade(
                    widget.inspectionId,
                    context,
                    method: 'copy',
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
