// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$communityRepositoryHash() =>
    r'f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1';

/// See also [communityRepository].
@ProviderFor(communityRepository)
final communityRepositoryProvider = Provider<CommunityRepository>.internal(
  communityRepository,
  name: r'communityRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$communityRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CommunityRepositoryRef = ProviderRef<CommunityRepository>;

String _$globalFeedHash() =>
    r'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b3';

/// See also [globalFeed].
@ProviderFor(globalFeed)
const globalFeedProvider = GlobalFeedFamily();

/// @macro riverpod_annotation.riverpod_family
class GlobalFeedFamily extends Family {
  /// @macro riverpod_annotation.riverpod_family
  const GlobalFeedFamily();

  /// @macro
  GlobalFeedProvider call(String filter) => GlobalFeedProvider(filter);

  @override
  GlobalFeedProvider getProviderOverride(
    covariant GlobalFeedProvider provider,
  ) {
    return call(provider.filter);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'globalFeedProvider';
}

/// @macro
class GlobalFeedProvider extends AutoDisposeFutureProvider<List<FeedItem>> {
  /// @macro
  GlobalFeedProvider(String filter)
      : this._internal(
          (ref) => globalFeed(ref as GlobalFeedRef, filter),
          from: globalFeedProvider,
          name: r'globalFeedProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$globalFeedHash,
          dependencies: null,
          allTransitiveDependencies: null,
          filter: filter,
        );

  GlobalFeedProvider._internal(
    super.create, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filter,
  }) : super.internal();

  final String filter;

  @override
  Override overrideWith(
    FutureOr<List<FeedItem>> Function(GlobalFeedRef ref) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GlobalFeedProvider._internal(
        (ref) => create(ref as GlobalFeedRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filter: filter,
      ),
    );
  }

  @override
  (String,) get argument => (filter,);

  @override
  AutoDisposeFutureProviderElement<List<FeedItem>> createElement() {
    return _GlobalFeedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GlobalFeedProvider && other.filter == filter;
  }

  @override
  int get hashCode => filter.hashCode;
}

/// @macro riverpod_annotation.riverpod_element
mixin GlobalFeedRef on AutoDisposeFutureProviderRef<List<FeedItem>> {
  String get filter;
}

class _GlobalFeedProviderElement
    extends AutoDisposeFutureProviderElement<List<FeedItem>>
    with GlobalFeedRef {
  _GlobalFeedProviderElement(super.provider);

  @override
  String get filter => (origin as GlobalFeedProvider).filter;
}

String _$followingFeedHash() =>
    r'b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c4';

/// See also [followingFeed].
@ProviderFor(followingFeed)
final followingFeedProvider =
    AutoDisposeFutureProvider<List<FeedItem>>.internal(
  followingFeed,
  name: r'followingFeedProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$followingFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FollowingFeedRef = AutoDisposeFutureProviderRef<List<FeedItem>>;

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
