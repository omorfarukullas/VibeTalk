import 'package:vibetalk/features/auth/domain/repositories/auth_repository.dart';

/// Use case: Log out the current user.
class LogoutUseCase {
  final AuthRepository _repository;
  const LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}
