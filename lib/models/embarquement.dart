class EmbarquementRequest {
  final int containerId;
  final List<int> packageId;

  EmbarquementRequest({required this.containerId, required this.packageId});

  Map<String, dynamic> toJson() => {
        'containerId': containerId,
        'packageId': packageId,
      };
}

/// Request body for POST /embarquer/items (add items to container).
class ContainerItemsRequest {
  final int containerId;
  final List<int> itemIds;

  ContainerItemsRequest({required this.containerId, required this.itemIds});

  Map<String, dynamic> toJson() => {
        'containerId': containerId,
        'itemIds': itemIds,
      };
}

class HarborEmbarquementRequest {
  final int harborId;
  final List<int> containerId;

  HarborEmbarquementRequest({
    required this.harborId,
    required this.containerId,
  });

  Map<String, dynamic> toJson() => {
        'harborId': harborId,
        'containerId': containerId,
      };
}
