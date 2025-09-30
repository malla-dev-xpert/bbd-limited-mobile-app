enum BranchEnum {
  CHINA("CN", "Chine", "🇨🇳"),
  CONGO("CG", "Congo", "🇨🇬"),
  MALI("ML", "Mali", "🇲🇱");

  const BranchEnum(this.code, this.name, this.flag);

  final String code;
  final String name;
  final String flag;

  static BranchEnum fromCode(String code) {
    for (BranchEnum branch in values) {
      if (branch.code == code) {
        return branch;
      }
    }
    throw ArgumentError('Code de branche invalide: $code');
  }

  static BranchEnum fromName(String name) {
    for (BranchEnum branch in values) {
      if (branch.name.toLowerCase() == name.toLowerCase()) {
        return branch;
      }
    }
    throw ArgumentError('Nom de branche invalide: $name');
  }

  static bool isValidCode(String code) {
    for (BranchEnum branch in values) {
      if (branch.code == code) {
        return true;
      }
    }
    return false;
  }

  static String getNameFromCode(String code) {
    return fromCode(code).name;
  }

  @override
  String toString() {
    return '$flag $name';
  }
}
