/// Determines how to transform the points given for a gradient.
enum DsvgGradientUnitMode {
  /// The gradient vector(s) are transformed by the space in the object containing the gradient.
  objectBoundingBox,

  /// The gradient vector(s) are taken as is.
  userSpaceOnUse,
}
