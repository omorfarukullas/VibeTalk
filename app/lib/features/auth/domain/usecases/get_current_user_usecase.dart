import 'package:vibetalk/features/auth/domain/entities/user_entity.dart';
import 'package:vibetalk/features/auth/domain/repositories/auth_repository.dart';

/// Use case: Get the currently authenticated user from local cache.
class GetCurrentUserUseCase {
  final AuthRepository _repository;
  const GetCurrentUserUseCase(this._repository);

  Future<UserEntity?> call() => _repository.getCurrentUser();
}
