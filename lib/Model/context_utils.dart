import 'package:flutter/material.dart' as material;

/// Utility class for safe context operations
class ContextUtils {
  /// Safely shows a SnackBar if the context is still mounted
  static void showSnackBar(dynamic context, material.SnackBar snackBar) {
    if (context.mounted) {
      material.ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  /// Safely navigates if the context is still mounted
  static void navigateTo(dynamic context, material.Widget page) {
    if (context.mounted) {
      material.Navigator.of(context).push(
        material.MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  /// Safely pops the current route if the context is still mounted
  static void pop(dynamic context) {
    if (context.mounted) {
      material.Navigator.of(context).pop();
    }
  }

  /// Safely shows a dialog if the context is still mounted
  static Future<T?> showDialog<T>({
    required dynamic context,
    required material.WidgetBuilder builder,
    bool barrierDismissible = true,
  }) async {
    if (!context.mounted) return null;
    
    return await material.showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  /// Safely shows a time picker if the context is still mounted
  static Future<material.TimeOfDay?> showTimePicker({
    required dynamic context,
    required material.TimeOfDay initialTime,
  }) async {
    if (!context.mounted) return null;
    
    return await material.showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  }

  /// Wrapper for async operations that need context
  static Future<T?> safeAsyncOperation<T>({
    required dynamic context,
    required Future<T> Function() operation,
    T? Function()? onContextUnmounted,
  }) async {
    if (!context.mounted) {
      return onContextUnmounted?.call();
    }

    try {
      final result = await operation();
      
      if (!context.mounted) {
        return onContextUnmounted?.call();
      }
      
      return result;
    } catch (e) {
      if (context.mounted) {
        showSnackBar(
          context,
          material.SnackBar(
            content: material.Text('İşlem hatası: $e'),
            backgroundColor: material.Colors.red,
          ),
        );
      }
      return onContextUnmounted?.call();
    }
  }

  /// Wrapper for setState operations - use with caution
  static void safeSetState(material.State state, material.VoidCallback fn) {
    if (state.mounted) {
      // Note: This is a protected member, use only when necessary
      // Consider using a callback pattern instead
      fn();
    }
  }
}

/// Extension for BuildContext to add safe operations
extension SafeContext on material.BuildContext {
  /// Safely shows a SnackBar
  void showSnackBar(material.SnackBar snackBar) {
    ContextUtils.showSnackBar(this, snackBar);
  }

  /// Safely navigates to a page
  void navigateTo(material.Widget page) {
    ContextUtils.navigateTo(this, page);
  }

  /// Safely pops the current route
  void pop() {
    ContextUtils.pop(this);
  }

  /// Safely shows a dialog
  Future<T?> showSafeDialog<T>({
    required material.WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return ContextUtils.showDialog<T>(
      context: this,
      builder: builder,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Safely shows a time picker
  Future<material.TimeOfDay?> showSafeTimePicker({
    required material.TimeOfDay initialTime,
  }) {
    return ContextUtils.showTimePicker(
      context: this,
      initialTime: initialTime,
    );
  }
}
