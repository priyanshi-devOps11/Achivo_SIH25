import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthHelper {
  static Future<bool> isUserLoggedIn() async {
    return Supabase.instance.client.auth.currentUser != null;
  }

  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    return await SupabaseService.getCurrentUserProfile();
  }

  static Future<void> signOut() async {
    await SupabaseService.signOut();
  }

  static String? getUserRole() {

    return Supabase.instance.client.auth.currentUser?.userMetadata?['role'];
  }
}
