import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../viewmodel/wallet_viewmodel.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print("🔥 WalletScreen initState() called");
    _initializeWalletData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print("🔥 App lifecycle changed: $state");

    if (state == AppLifecycleState.resumed) {
      // App resumed, refresh wallet data
      final walletVM = context.read<WalletViewModel>();
      walletVM.fetchWalletData();
    }
  }

  Future<void> _initializeWalletData() async {
    if (_hasInitialized) return;

    print("🔥 _initializeWalletData() called");

    // Wait for next frame to ensure Provider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final walletVM = context.read<WalletViewModel>();

      print("🔥 Current wallet balance: ${walletVM.walletBalance}");
      print("🔥 Is loading: ${walletVM.isLoading}");
      print("🔥 Is initialized: ${walletVM.isInitialized}");

      // If not initialized or balance is 0, fetch data
      if (!walletVM.isInitialized || walletVM.walletBalance == 0.0) {
        print("🔥 Fetching wallet data from initState");
        await walletVM.fetchWalletData();
      }

      _hasInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    print("🔥 WalletScreen build() called");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange.shade600,
        centerTitle: true,
        title: const Text(
          "My Wallet",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Debug refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              print("🔥 Manual refresh triggered");
              final walletVM = context.read<WalletViewModel>();
              await walletVM.forceRefresh();
            },
          ),
        ],
      ),
      body: Consumer<WalletViewModel>(
        builder: (context, walletVM, child) {
          print(
            "🔥 Consumer builder called - Balance: ${walletVM.walletBalance}",
          );

          return RefreshIndicator(
            onRefresh: () async {
              print("🔥 Pull to refresh triggered");
              await walletVM.forceRefresh();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF43A047),
                          Color(0xFF66BB6A),
                        ], // Dark → Light Green
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Wallet Balance",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        walletVM.isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                "₹ ${walletVM.walletBalance.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Recent Transactions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  /// Transactions List
                  Expanded(
                    child: walletVM.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : walletVM.transactions.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No transactions yet.",
                                  style: TextStyle(color: Colors.grey),
                                ),

                                const SizedBox(height: 36),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.note,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "If wallet balance is not showing correctly,login again",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: walletVM.transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = walletVM.transactions[index];
                              final bool isDebit =
                                  transaction.amount < 0 ||
                                  transaction.type.toLowerCase().contains(
                                    'debit',
                                  );

                              return TransactionTile(
                                icon: isDebit
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                title: transaction.type,
                                subtitle: DateFormat(
                                  'dd MMM, yyyy',
                                ).format(transaction.timestamp.toDate()),
                                amount:
                                    "${isDebit ? '-' : '+'} ₹${transaction.amount.abs().toStringAsFixed(2)}",
                                isDebit: isDebit,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isDebit;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isDebit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: isDebit
              ? Colors.red.withOpacity(0.1)
              : Colors.green.withOpacity(0.1),
          child: Icon(icon, color: isDebit ? Colors.red : Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDebit ? Colors.red : Colors.green,
          ),
        ),
      ),
    );
  }
}
