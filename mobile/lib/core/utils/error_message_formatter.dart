import 'dart:io';
import 'package:dio/dio.dart';

/// Utility class for formatting error messages to be more user-friendly
class ErrorMessageFormatter {
  /// Returns a short, safe message for display to users.
  /// Handles DioException, SocketException; otherwise returns a generic message.
  static String getUserFacingMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString().trim();
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Connection failed. Please check your network.';
      }
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!
            .replaceAll('Exception: ', '')
            .replaceAll('DioException: ', '')
            .trim();
      }
      return 'Something went wrong. Please try again.';
    }
    if (e is SocketException) {
      return 'No network connection. Please check your connection.';
    }
    if (e is String) {
      return e
          .replaceAll('Exception: ', '')
          .replaceAll('DioException: ', '')
          .trim();
    }
    return 'Something went wrong. Please try again.';
  }
  /// Formats distance-related error messages to be more informative
  /// 
  /// Example input: "You are 10340.0 meters away from the destination. Please get within 5 meters to mark destination as reached."
  /// Example output: "You are 10.34 km away from the destination. Please move closer (within 5 meters) to mark it as reached."
  static String formatDistanceError(String errorMessage) {
    // Try to extract distance from the error message
    final distanceRegex = RegExp(r'(\d+\.?\d*)\s*(meters?|m|kilometers?|km)', caseSensitive: false);
    final match = distanceRegex.firstMatch(errorMessage);
    
    if (match != null) {
      final distanceValue = double.tryParse(match.group(1) ?? '');
      final distanceUnit = match.group(2)?.toLowerCase() ?? '';
      
      if (distanceValue != null) {
        String formattedDistance;
        String unit;
        
        // Convert to kilometers if distance is large (>= 1000 meters)
        if (distanceUnit.contains('meter') || distanceUnit == 'm') {
          if (distanceValue >= 1000) {
            formattedDistance = (distanceValue / 1000).toStringAsFixed(2);
            unit = 'km';
          } else {
            formattedDistance = distanceValue.toStringAsFixed(1);
            unit = 'meters';
          }
        } else {
          formattedDistance = distanceValue.toStringAsFixed(2);
          unit = 'km';
        }
        
        // Extract the context (destination, waypoint, office, etc.)
        String context = 'destination';
        if (errorMessage.toLowerCase().contains('waypoint')) {
          context = 'waypoint';
        } else if (errorMessage.toLowerCase().contains('office')) {
          context = 'office';
        }
        
        // Build a more informative message
        return 'You are $formattedDistance $unit away from the $context. '
               'Please move closer (within 5 meters) to mark it as reached.';
      }
    }
    
    // If we can't parse the distance, return a cleaned version of the original message
    return errorMessage
        .replaceAll('Exception: ', '')
        .replaceAll('DioException: ', '')
        .replaceAll('DioError: ', '')
        .trim();
  }
  
  /// Formats general API error messages to be more user-friendly
  static String formatApiError(dynamic error) {
    if (error is String) {
      // Check if it's a distance error
      if (error.toLowerCase().contains('meters away') || 
          error.toLowerCase().contains('meters from')) {
        return formatDistanceError(error);
      }
      
      // Clean up technical error messages
      return error
          .replaceAll('Exception: ', '')
          .replaceAll('DioException: ', '')
          .replaceAll('DioError: ', '')
          .trim();
    }
    
    return 'An error occurred. Please try again.';
  }
  
  /// Extracts error message from DioException response
  static String extractErrorMessage(dynamic error) {
    try {
      if (error is Map) {
        return error['message'] ?? 
               error['error'] ?? 
               error['detail'] ?? 
               'An error occurred';
      }
      
      if (error is String) {
        return error;
      }
      
      return error.toString();
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }
}
