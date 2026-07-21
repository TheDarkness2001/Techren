function softDeletePlugin(schema) {
  schema.add({
    isDeleted: { type: Boolean, default: false, index: true },
    deletedAt: { type: Date, default: null },
    deletedBy: { type: String, default: null },
  });

  const excludeDeleted = function excludeDeleted() {
    if (this.getOptions().includeDeleted) return;
    this.where({ isDeleted: { $ne: true } });
  };

  schema.pre(/^find/, excludeDeleted);
  schema.pre('countDocuments', excludeDeleted);
}

module.exports = softDeletePlugin;
