// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UploadItem {
  /// Stable ID for this queue entry.
  String get id => throw _privateConstructorUsedError;

  /// File name as picked by the guest (display only).
  String get originalFileName => throw _privateConstructorUsedError;

  /// Size of the picked file in bytes.
  int get sizeBytes => throw _privateConstructorUsedError;

  /// Archive-safe storage object key following
  /// `{sanitized-name}-{batch-uuid}/{safe-original-filename}`.
  String get objectKey => throw _privateConstructorUsedError;

  /// Current lifecycle status of this item.
  UploadStatus get status => throw _privateConstructorUsedError;

  /// Bytes already transmitted for this item.
  int get bytesSent => throw _privateConstructorUsedError;

  /// Raw storage error detail, set when [status] is
  /// [UploadStatus.failed]. Never shown to guests verbatim.
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of UploadItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UploadItemCopyWith<UploadItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UploadItemCopyWith<$Res> {
  factory $UploadItemCopyWith(
    UploadItem value,
    $Res Function(UploadItem) then,
  ) = _$UploadItemCopyWithImpl<$Res, UploadItem>;
  @useResult
  $Res call({
    String id,
    String originalFileName,
    int sizeBytes,
    String objectKey,
    UploadStatus status,
    int bytesSent,
    String? errorMessage,
  });
}

/// @nodoc
class _$UploadItemCopyWithImpl<$Res, $Val extends UploadItem>
    implements $UploadItemCopyWith<$Res> {
  _$UploadItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UploadItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? originalFileName = null,
    Object? sizeBytes = null,
    Object? objectKey = null,
    Object? status = null,
    Object? bytesSent = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            originalFileName: null == originalFileName
                ? _value.originalFileName
                : originalFileName // ignore: cast_nullable_to_non_nullable
                      as String,
            sizeBytes: null == sizeBytes
                ? _value.sizeBytes
                : sizeBytes // ignore: cast_nullable_to_non_nullable
                      as int,
            objectKey: null == objectKey
                ? _value.objectKey
                : objectKey // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as UploadStatus,
            bytesSent: null == bytesSent
                ? _value.bytesSent
                : bytesSent // ignore: cast_nullable_to_non_nullable
                      as int,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UploadItemImplCopyWith<$Res>
    implements $UploadItemCopyWith<$Res> {
  factory _$$UploadItemImplCopyWith(
    _$UploadItemImpl value,
    $Res Function(_$UploadItemImpl) then,
  ) = __$$UploadItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String originalFileName,
    int sizeBytes,
    String objectKey,
    UploadStatus status,
    int bytesSent,
    String? errorMessage,
  });
}

/// @nodoc
class __$$UploadItemImplCopyWithImpl<$Res>
    extends _$UploadItemCopyWithImpl<$Res, _$UploadItemImpl>
    implements _$$UploadItemImplCopyWith<$Res> {
  __$$UploadItemImplCopyWithImpl(
    _$UploadItemImpl _value,
    $Res Function(_$UploadItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UploadItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? originalFileName = null,
    Object? sizeBytes = null,
    Object? objectKey = null,
    Object? status = null,
    Object? bytesSent = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$UploadItemImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        originalFileName: null == originalFileName
            ? _value.originalFileName
            : originalFileName // ignore: cast_nullable_to_non_nullable
                  as String,
        sizeBytes: null == sizeBytes
            ? _value.sizeBytes
            : sizeBytes // ignore: cast_nullable_to_non_nullable
                  as int,
        objectKey: null == objectKey
            ? _value.objectKey
            : objectKey // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as UploadStatus,
        bytesSent: null == bytesSent
            ? _value.bytesSent
            : bytesSent // ignore: cast_nullable_to_non_nullable
                  as int,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$UploadItemImpl extends _UploadItem {
  const _$UploadItemImpl({
    required this.id,
    required this.originalFileName,
    required this.sizeBytes,
    required this.objectKey,
    this.status = UploadStatus.pending,
    this.bytesSent = 0,
    this.errorMessage,
  }) : super._();

  /// Stable ID for this queue entry.
  @override
  final String id;

  /// File name as picked by the guest (display only).
  @override
  final String originalFileName;

  /// Size of the picked file in bytes.
  @override
  final int sizeBytes;

  /// Archive-safe storage object key following
  /// `{sanitized-name}-{batch-uuid}/{safe-original-filename}`.
  @override
  final String objectKey;

  /// Current lifecycle status of this item.
  @override
  @JsonKey()
  final UploadStatus status;

  /// Bytes already transmitted for this item.
  @override
  @JsonKey()
  final int bytesSent;

  /// Raw storage error detail, set when [status] is
  /// [UploadStatus.failed]. Never shown to guests verbatim.
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'UploadItem(id: $id, originalFileName: $originalFileName, sizeBytes: $sizeBytes, objectKey: $objectKey, status: $status, bytesSent: $bytesSent, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UploadItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.originalFileName, originalFileName) ||
                other.originalFileName == originalFileName) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.objectKey, objectKey) ||
                other.objectKey == objectKey) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.bytesSent, bytesSent) ||
                other.bytesSent == bytesSent) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    originalFileName,
    sizeBytes,
    objectKey,
    status,
    bytesSent,
    errorMessage,
  );

  /// Create a copy of UploadItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UploadItemImplCopyWith<_$UploadItemImpl> get copyWith =>
      __$$UploadItemImplCopyWithImpl<_$UploadItemImpl>(this, _$identity);
}

abstract class _UploadItem extends UploadItem {
  const factory _UploadItem({
    required final String id,
    required final String originalFileName,
    required final int sizeBytes,
    required final String objectKey,
    final UploadStatus status,
    final int bytesSent,
    final String? errorMessage,
  }) = _$UploadItemImpl;
  const _UploadItem._() : super._();

  /// Stable ID for this queue entry.
  @override
  String get id;

  /// File name as picked by the guest (display only).
  @override
  String get originalFileName;

  /// Size of the picked file in bytes.
  @override
  int get sizeBytes;

  /// Archive-safe storage object key following
  /// `{sanitized-name}-{batch-uuid}/{safe-original-filename}`.
  @override
  String get objectKey;

  /// Current lifecycle status of this item.
  @override
  UploadStatus get status;

  /// Bytes already transmitted for this item.
  @override
  int get bytesSent;

  /// Raw storage error detail, set when [status] is
  /// [UploadStatus.failed]. Never shown to guests verbatim.
  @override
  String? get errorMessage;

  /// Create a copy of UploadItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UploadItemImplCopyWith<_$UploadItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
