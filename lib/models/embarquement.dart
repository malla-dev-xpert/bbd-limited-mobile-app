class EmbarquementRequest {
  final int containerId;
  final List<int> packageId;

  EmbarquementRequest({required this.containerId, required this.packageId});

  Map<String, dynamic> toJson() => {
    'containerId': containerId,
    'packageId': packageId,
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
