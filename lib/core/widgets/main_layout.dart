import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          border: const Border(
            top: BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  '/home',
                  Icons.home,
                  'Accueil',
                  currentPath == '/home',
                ),
                _buildNavItem(
                  context,
                  '/finance',
                  Icons.account_balance_wallet,
                  'Finance',
                  currentPath == '/finance',
                ),
                _buildNavItem(
                  context,
                  '/projets',
                  Icons.folder_outlined,
                  'Projets',
                  currentPath == '/projets',
                ),
                _buildNavItem(
                  context,
                  '/signalements',
                  Icons.warning_outlined,
                  'Signalements',
                  currentPath == '/signalements',
                ),
                _buildNavItem(
                  context,
                  '/cadre-de-vie',
                  Icons.nature_people,
                  'Cadre de vie',
                  currentPath == '/cadre-de-vie',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String path,
    IconData icon,
    String label,
    bool isActive,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(path),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive 
                    ? const Color(0xFF4F46E5) 
                    : const Color(0xFF9CA3AF),
                size: 22,
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive 
                        ? const Color(0xFF4F46E5) 
                        : const Color(0xFF9CA3AF),
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