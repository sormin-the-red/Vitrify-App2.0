// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixes_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mixesRepositoryHash() =>
    r'f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2';

/// See also [mixesRepository].
@ProviderFor(mixesRepository)
final mixesRepositoryProvider = Provider<MixesRepository>.internal(
  mixesRepository,
  name: r'mixesRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$mixesRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MixesRepositoryRef = ProviderRef<MixesRepository>;

// ── mixDetail family ─────────────────────────────────────────────────────────

String _$mixDetailHash() =>
    r'a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3';

/// See also [mixDetail].
@ProviderFor(mixDetail)
const mixDetailProvider = MixDetailFamily();

/// @macro riverpod_annotation.riverpod_family
class MixDetailFamily extends Family {
  /// @macro riverpod_annotation.riverpod_family
  const MixDetailFamily();

  /// @macro
  MixDetailProvider call(String id) => MixDetailProvider(id);

  @override
  MixDetailProvider getProviderOverride(
    covariant MixDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'mixDetailProvider';
}

/// @macro
class MixDetailProvider extends AutoDisposeFutureProvider<GlazeMix> {
  /// @macro
  MixDetailProvider(String id)
      : this._internal(
          (ref) => mixDetail(ref as MixDetailRef, id),
          from: mixDetailProvider,
          name: r'mixDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$mixDetailHash,
          dependencies: null,
          allTransitiveDependencies: null,
          id: id,
        );

  MixDetailProvider._internal(
    super.create, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<GlazeMix> Function(MixDetailRef ref) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: MixDetailProvider._internal(
        (ref) => create(ref as MixDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  (String,) get argument => (id,);

  @override
  AutoDisposeFutureProviderElement<GlazeMix> createElement() {
    return _MixDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MixDetailProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// @macro riverpod_annotation.riverpod_element
mixin MixDetailRef on AutoDisposeFutureProviderRef<GlazeMix> {
  String get id;
}

class _MixDetailProviderElement
    extends AutoDisposeFutureProviderElement<GlazeMix> with MixDetailRef {
  _MixDetailProviderElement(super.provider);

  @override
  String get id => (origin as MixDetailProvider).id;
}

// ── recipeMixes family ───────────────────────────────────────────────────────

String _$recipeMixesHash() =>
    r'b3c4d5e6f1a2b3c4d5e6f1a2b3c4d5e6f1a2b3c4';

/// See also [recipeMixes].
@ProviderFor(recipeMixes)
const recipeMixesProvider = RecipeMixesFamily();

/// @macro riverpod_annotation.riverpod_family
class RecipeMixesFamily extends Family {
  /// @macro riverpod_annotation.riverpod_family
  const RecipeMixesFamily();

  /// @macro
  RecipeMixesProvider call(String recipeId) => RecipeMixesProvider(recipeId);

  @override
  RecipeMixesProvider getProviderOverride(
    covariant RecipeMixesProvider provider,
  ) {
    return call(provider.recipeId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'recipeMixesProvider';
}

/// @macro
class RecipeMixesProvider
    extends AutoDisposeFutureProvider<List<MixSummary>> {
  /// @macro
  RecipeMixesProvider(String recipeId)
      : this._internal(
          (ref) => recipeMixes(ref as RecipeMixesRef, recipeId),
          from: recipeMixesProvider,
          name: r'recipeMixesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recipeMixesHash,
          dependencies: null,
          allTransitiveDependencies: null,
          recipeId: recipeId,
        );

  RecipeMixesProvider._internal(
    super.create, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.recipeId,
  }) : super.internal();

  final String recipeId;

  @override
  Override overrideWith(
    FutureOr<List<MixSummary>> Function(RecipeMixesRef ref) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecipeMixesProvider._internal(
        (ref) => create(ref as RecipeMixesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        recipeId: recipeId,
      ),
    );
  }

  @override
  (String,) get argument => (recipeId,);

  @override
  AutoDisposeFutureProviderElement<List<MixSummary>> createElement() {
    return _RecipeMixesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeMixesProvider && other.recipeId == recipeId;
  }

  @override
  int get hashCode => recipeId.hashCode;
}

/// @macro riverpod_annotation.riverpod_element
mixin RecipeMixesRef on AutoDisposeFutureProviderRef<List<MixSummary>> {
  String get recipeId;
}

class _RecipeMixesProviderElement
    extends AutoDisposeFutureProviderElement<List<MixSummary>>
    with RecipeMixesRef {
  _RecipeMixesProviderElement(super.provider);

  @override
  String get recipeId => (origin as RecipeMixesProvider).recipeId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
