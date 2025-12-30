/// Utility functions for normalizing and comparing IDs
/// Handles both string and ObjectId formats from MongoDB
class IdUtils {
  /// Normalizes an ID to a string for comparison
  /// Handles: String, ObjectId (with toString()), Map with _id/id, null
  static String normalizeId(dynamic id) {
    if (id == null) return '';
    
    // If it's already a string, return it
    if (id is String) {
      return id.trim();
    }
    
    // If it's a Map (populated object), extract _id or id
    if (id is Map) {
      final extractedId = id['_id'] ?? id['id'];
      if (extractedId != null) {
        return extractedId.toString().trim();
      }
      return '';
    }
    
    // For any other type (including ObjectId), convert to string
    return id.toString().trim();
  }
  
  /// Compares two IDs for equality, handling different formats
  static bool areIdsEqual(dynamic id1, dynamic id2) {
    if (id1 == null && id2 == null) return true;
    if (id1 == null || id2 == null) return false;
    
    final normalized1 = normalizeId(id1);
    final normalized2 = normalizeId(id2);
    
    // Empty strings should not match
    if (normalized1.isEmpty || normalized2.isEmpty) {
      return false;
    }
    
    return normalized1 == normalized2;
  }
  
  /// Checks if an ID is in a list of IDs
  static bool isIdInList(dynamic id, List<dynamic> idList) {
    if (id == null || idList.isEmpty) return false;
    
    final normalizedId = normalizeId(id);
    if (normalizedId.isEmpty) return false;
    
    return idList.any((listId) => areIdsEqual(normalizedId, listId));
  }
}
