import 'package:darshan_trip/features/profile/viewmodel/profile_screen_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileScreenViewModel(),
      child: Consumer<ProfileScreenViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                // AppBar with Profile Header
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF5A623), Color(0xFFF76C38)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.network(
                              viewModel.backgroundImage,
                              fit: BoxFit.cover,
                              color: Colors.black.withOpacity(0.3),
                              colorBlendMode: BlendMode.darken,
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: 16,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 36,
                                    backgroundImage: NetworkImage(
                                      viewModel.profileImage,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    viewModel.isLoading
                                        ? const SizedBox(
                                            width: 120,
                                            height: 20,
                                            child: LinearProgressIndicator(
                                              backgroundColor: Colors.white24,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            viewModel.userName,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                    const SizedBox(height: 4),
                                    viewModel.isLoading
                                        ? const SizedBox(
                                            width: 120,
                                            height: 16,
                                            child: LinearProgressIndicator(
                                              backgroundColor: Colors.white24,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            viewModel.email,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70,
                                            ),
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Body Content
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'My Details'),

                    // ✅ New "Edit Profile" Tile
                    _buildListTile(
                      context,
                      icon: Icons.edit,
                      title: 'Edit Profile',
                      onTap: () => viewModel.onEditProfileTap(context),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Payments'),
                    _buildListTile(
                      context,
                      icon: Icons.account_balance_wallet,
                      title: 'Wallet',
                      onTap: () => viewModel.onWalletTap(context),
                    ),

                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'More'),
                    _buildListTile(
                      context,
                      icon: Icons.share,
                      title: 'Referrals',
                      onTap: () => viewModel.onReferralsTap(context),
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.info,
                      title: 'Know about Darshan Trip',
                      onTap: () => viewModel.onKnowAboutTap(context),
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.star,
                      title: 'Rate App',
                      onTap: () => viewModel.onRateAppTap(context),
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () => Navigator.pushNamed(context, '/logout'),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFF5A623), size: 28),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade600),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      ),
    );
  }
}
