import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';

class AccountSidebar extends StatelessWidget {
  const AccountSidebar({
    super.key,
    required this.onClose,
    required this.onAccountInfo,
    required this.onLogout,
    required this.onLogin,
    required this.onContact,
    this.email,
    this.isAnonymous = false,
  });

  final VoidCallback onClose;
  final VoidCallback onAccountInfo;
  final VoidCallback onLogout;
  final VoidCallback onLogin;
  final VoidCallback onContact;
  final String? email;
  final bool isAnonymous;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(-5, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ヘッダー
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (email != null && email!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        email!,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // メニュー項目
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // SidebarMenuItem(
                    //   icon: Icons.person_outline_rounded,
                    //   text: 'アカウント情報',
                    //   onTap: onAccountInfo,
                    // ),
                    SidebarMenuItem(
                      icon: Icons.help_outline_rounded,
                      text: 'お問い合わせ',
                      onTap: onContact,
                    ),
                    const SizedBox(height: 8),
                    SidebarMenuItem(
                      icon: isAnonymous
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      text: isAnonymous ? 'ログイン' : 'ログアウト',
                      onTap: isAnonymous ? onLogin : onLogout,
                      isDestructive: !isAnonymous,
                    ),
                    const SizedBox(height: 8),
                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SidebarMenuItem extends StatelessWidget {
  const SidebarMenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDestructive ? Colors.red.shade400 : AppColors.textSecondary;
    final textColor =
        isDestructive ? Colors.red.shade600 : AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDestructive
                    ? Colors.red.shade50
                    : AppColors.textSecondary.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary.withOpacity(0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
