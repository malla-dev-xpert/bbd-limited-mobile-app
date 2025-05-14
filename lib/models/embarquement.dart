class EmbarquementRequest {
  final int containerId;
  final List<int> packageId;

  EmbarquementRequest({required this.containerId, required this.packageId});

  Map<String, dynamic> toJson() => {
    'containerId': containerId,
    'packageId': packageId,
  };
}
