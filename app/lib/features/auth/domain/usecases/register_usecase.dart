import 'package:vibetalk/features/auth/domain/entities/user_entity.dart';
import 'package:vibetalk/features/auth/domain/repositories/auth_repository.dart';

/// Use case: Register or log in via Firebase phone OTP token.
class RegisterUseCase {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  Future<UserEntity> call(String firebaseToken) =>
      _repository.register(firebaseToken);
}
