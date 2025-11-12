import '../core/enums/branch_enum.dart';

class Branch {
  final BranchEnum branchEnum;
  final String code;
  final String name;
  final String flag;

  Branch({
    required this.branchEnum,
    required this.code,
    required this.name,
    required this.flag,
  });

  factory Branch.fromEnum(BranchEnum branchEnum) {
    return Branch(
      branchEnum: branchEnum,
      code: branchEnum.code,
      name: branchEnum.name,
      flag: branchEnum.flag,
    );
  }

  factory Branch.fromCode(String code) {
    final branchEnum = BranchEnum.fromCode(code);
    return Branch.fromEnum(branchEnum);
  }

  factory Branch.fromName(String name) {
    final branchEnum = BranchEnum.fromName(name);
    return Branch.fromEnum(branchEnum);
  }

  static List<Branch> getAllBranches() {
    return BranchEnum.values
        .map((branchEnum) => Branch.fromEnum(branchEnum))
        .toList();
  }

  @override
  String toString() {
    return '$flag $name';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Branch && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}
