import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/admin_auth_provider.dart';

class AdminAuthGuard {
  static String? redirect(BuildContext context, GoRouterState state) {
    final adminAuthProvider = context.read<AdminAuthProvider>();
    
    // If trying to access admin pages and not authenticated
    if (state.matchedLocation.startsWith('/admin') && 
        state.matchedLocation != '/admin/login' &&
        !adminAuthProvider.isAuthenticated) {
      return '/admin/login';
    }
    
    // If trying to access admin login while already authenticated
    if (state.matchedLocation == '/admin/login' && 
        adminAuthProvider.isAuthenticated) {
      return '/admin/dashboard';
    }
    
    return null; // No redirect needed
  }
}