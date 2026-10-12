// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'event_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$EventConfig {
  /// Access key ID of the per-event storage credentials (`k`).
  String get accessKeyId => throw _privateConstructorUsedError;

  /// Secret key of the per-event storage credentials (`s`).
  String get secretKey => throw _privateConstructorUsedError;

  /// Bucket named after the event, e.g. `wedding-20261025` (`b`).
  String get bucket => throw _privateConstructorUsedError;

  /// Signing region of the bucket (`r`).
  String get region => throw _privateConstructorUsedError;

  /// Optional custom S3-compatible endpoint (`ep?`). Null targets AWS S3.
  String? get endpoint => throw _privateConstructorUsedError;

  /// Create a copy of EventConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EventConfigCopyWith<EventConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventConfigCopyWith<$Res> {
  factory $EventConfigCopyWith(
    EventConfig value,
    $Res Function(EventConfig) then,
  ) = _$EventConfigCopyWithImpl<$Res, EventConfig>;
  @useResult
  $Res call({
    String accessKeyId,
    String secretKey,
    String bucket,
    String region,
    String? endpoint,
  });
}

/// @nodoc
class _$EventConfigCopyWithImpl<$Res, $Val extends EventConfig>
    implements $EventConfigCopyWith<$Res> {
  _$EventConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EventConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessKeyId = null,
    Object? secretKey = null,
    Object? bucket = null,
    Object? region = null,
    Object? endpoint = freezed,
  }) {
    return _then(
      _value.copyWith(
            accessKeyId: null == accessKeyId
                ? _value.accessKeyId
                : accessKeyId // ignore: cast_nullable_to_non_nullable
                      as String,
            secretKey: null == secretKey
                ? _value.secretKey
                : secretKey // ignore: cast_nullable_to_non_nullable
                      as String,
            bucket: null == bucket
                ? _value.bucket
                : bucket // ignore: cast_nullable_to_non_nullable
                      as String,
            region: null == region
                ? _value.region
                : region // ignore: cast_nullable_to_non_nullable
                      as String,
            endpoint: freezed == endpoint
                ? _value.endpoint
                : endpoint // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EventConfigImplCopyWith<$Res>
    implements $EventConfigCopyWith<$Res> {
  factory _$$EventConfigImplCopyWith(
    _$EventConfigImpl value,
    $Res Function(_$EventConfigImpl) then,
  ) = __$$EventConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accessKeyId,
    String secretKey,
    String bucket,
    String region,
    String? endpoint,
  });
}

/// @nodoc
class __$$EventConfigImplCopyWithImpl<$Res>
    extends _$EventConfigCopyWithImpl<$Res, _$EventConfigImpl>
    implements _$$EventConfigImplCopyWith<$Res> {
  __$$EventConfigImplCopyWithImpl(
    _$EventConfigImpl _value,
    $Res Function(_$EventConfigImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EventConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessKeyId = null,
    Object? secretKey = null,
    Object? bucket = null,
    Object? region = null,
    Object? endpoint = freezed,
  }) {
    return _then(
      _$EventConfigImpl(
        accessKeyId: null == accessKeyId
            ? _value.accessKeyId
            : accessKeyId // ignore: cast_nullable_to_non_nullable
                  as String,
        secretKey: null == secretKey
            ? _value.secretKey
            : secretKey // ignore: cast_nullable_to_non_nullable
                  as String,
        bucket: null == bucket
            ? _value.bucket
            : bucket // ignore: cast_nullable_to_non_nullable
                  as String,
        region: null == region
            ? _value.region
            : region // ignore: cast_nullable_to_non_nullable
                  as String,
        endpoint: freezed == endpoint
            ? _value.endpoint
            : endpoint // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$EventConfigImpl extends _EventConfig {
  const _$EventConfigImpl({
    required this.accessKeyId,
    required this.secretKey,
    required this.bucket,
    required this.region,
    this.endpoint,
  }) : super._();

  /// Access key ID of the per-event storage credentials (`k`).
  @override
  final String accessKeyId;

  /// Secret key of the per-event storage credentials (`s`).
  @override
  final String secretKey;

  /// Bucket named after the event, e.g. `wedding-20261025` (`b`).
  @override
  final String bucket;

  /// Signing region of the bucket (`r`).
  @override
  final String region;

  /// Optional custom S3-compatible endpoint (`ep?`). Null targets AWS S3.
  @override
  final String? endpoint;

  @override
  String toString() {
    return 'EventConfig(accessKeyId: $accessKeyId, secretKey: $secretKey, bucket: $bucket, region: $region, endpoint: $endpoint)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventConfigImpl &&
            (identical(other.accessKeyId, accessKeyId) ||
                other.accessKeyId == accessKeyId) &&
            (identical(other.secretKey, secretKey) ||
                other.secretKey == secretKey) &&
            (identical(other.bucket, bucket) || other.bucket == bucket) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.endpoint, endpoint) ||
                other.endpoint == endpoint));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    accessKeyId,
    secretKey,
    bucket,
    region,
    endpoint,
  );

  /// Create a copy of EventConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EventConfigImplCopyWith<_$EventConfigImpl> get copyWith =>
      __$$EventConfigImplCopyWithImpl<_$EventConfigImpl>(this, _$identity);
}

abstract class _EventConfig extends EventConfig {
  const factory _EventConfig({
    required final String accessKeyId,
    required final String secretKey,
    required final String bucket,
    required final String region,
    final String? endpoint,
  }) = _$EventConfigImpl;
  const _EventConfig._() : super._();

  /// Access key ID of the per-event storage credentials (`k`).
  @override
  String get accessKeyId;

  /// Secret key of the per-event storage credentials (`s`).
  @override
  String get secretKey;

  /// Bucket named after the event, e.g. `wedding-20261025` (`b`).
  @override
  String get bucket;

  /// Signing region of the bucket (`r`).
  @override
  String get region;

  /// Optional custom S3-compatible endpoint (`ep?`). Null targets AWS S3.
  @override
  String? get endpoint;

  /// Create a copy of EventConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EventConfigImplCopyWith<_$EventConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
