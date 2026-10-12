import 'package:uuid/uuid.dart';

/// Produces a UUID4 string (used for batch and item identifiers).
typedef UuidGenerator = String Function();

const _uuid = Uuid();

/// Default UUID4 generator used across the guest flow.
String uuidV4() => _uuid.v4();
