import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:innervoices/blocs/user/user_bloc.dart';
import 'package:innervoices/models/user.dart';

class BradDrawer extends StatefulWidget {
  const BradDrawer({super.key});

  @override
  State<BradDrawer> createState() => _BradDrawerState();
}

class _BradDrawerState extends State<BradDrawer> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is UserAuthenticated) {
                final UserModel user = state.user;
                return _buildUserHeader(user);
              }
              return _buildEmptyHeader();
            },
          ),
          _buildAnimatedDetails(),

          _buildMainDrawerItems(),
        ],
      ),
    );
  }

  Widget _buildUserHeader(UserModel user) {
    return UserAccountsDrawerHeader(
      accountName: Text(user.username),
      accountEmail: Text(user.email),
      currentAccountPicture: _buildProfilePicture(user.profilePictureUrl),
      decoration: const BoxDecoration(color: Colors.deepPurple),
      onDetailsPressed: () {
        setState(() {
          _showDetails = !_showDetails;
        });
      },
    );
  }

  Widget _buildEmptyHeader() {
    return const DrawerHeader(
      decoration: BoxDecoration(color: Colors.deepPurple),
      child: Text(
        'Welcome!',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildAnimatedDetails() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: _showDetails
          ? Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.switch_account),
                  title: const Text('Switch Account'),
                  onTap: () {
                    // Navigate to switch account or perform action
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    context.read<UserBloc>().add(SignOutRequested());
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildMainDrawerItems() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Account'),
          onTap: () {
            // Navigate to account page or perform action
            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _buildProfilePicture(String url) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      foregroundImage: NetworkImage(url),
      child: const Icon(Icons.person, size: 50, color: Colors.grey),
    );
  }
}
