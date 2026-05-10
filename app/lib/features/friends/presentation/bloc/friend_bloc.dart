import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibetalk/features/friends/data/repositories/friend_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class FriendEvent {}

class LoadFriendsEvent extends FriendEvent {}

class SendFriendRequestEvent extends FriendEvent {
  final String addresseeId;
  SendFriendRequestEvent(this.addresseeId);
}

class RespondToRequestEvent extends FriendEvent {
  final String requestId;
  final String action; // 'accept' | 'decline'
  RespondToRequestEvent(this.requestId, this.action);
}

class RemoveFriendEvent extends FriendEvent {
  final String friendId;
  RemoveFriendEvent(this.friendId);
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class FriendState {}

class FriendInitial extends FriendState {}

class FriendLoading extends FriendState {}

class FriendsLoaded extends FriendState {
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> pendingRequests;

  FriendsLoaded({required this.friends, required this.pendingRequests});

  FriendsLoaded copyWith({
    List<Map<String, dynamic>>? friends,
    List<Map<String, dynamic>>? pendingRequests,
  }) {
    return FriendsLoaded(
      friends: friends ?? this.friends,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }
}

class FriendActionSuccess extends FriendState {
  final String message;
  FriendActionSuccess(this.message);
}

class FriendError extends FriendState {
  final String message;
  FriendError(this.message);
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class FriendBloc extends Bloc<FriendEvent, FriendState> {
  final FriendRepository _repository;

  FriendBloc({required FriendRepository repository})
      : _repository = repository,
        super(FriendInitial()) {
    on<LoadFriendsEvent>(_onLoad);
    on<SendFriendRequestEvent>(_onSendRequest);
    on<RespondToRequestEvent>(_onRespond);
    on<RemoveFriendEvent>(_onRemove);
  }

  Future<void> _onLoad(LoadFriendsEvent event, Emitter<FriendState> emit) async {
    emit(FriendLoading());
    try {
      final friends = await _repository.getFriends();
      final pending = await _repository.getPendingRequests();
      emit(FriendsLoaded(friends: friends, pendingRequests: pending));
    } catch (e) {
      emit(FriendError('Failed to load friends: $e'));
    }
  }

  Future<void> _onSendRequest(
    SendFriendRequestEvent event,
    Emitter<FriendState> emit,
  ) async {
    try {
      final result = await _repository.sendRequest(event.addresseeId);
      final message = result['message'] as String? ?? 'Friend request sent!';
      emit(FriendActionSuccess(message));
      // Reload to keep state fresh
      add(LoadFriendsEvent());
    } catch (e) {
      emit(FriendError('Failed to send request: $e'));
      add(LoadFriendsEvent());
    }
  }

  Future<void> _onRespond(
    RespondToRequestEvent event,
    Emitter<FriendState> emit,
  ) async {
    try {
      await _repository.respondToRequest(event.requestId, event.action);
      final msg = event.action == 'accept' ? 'Friend request accepted!' : 'Request declined.';
      emit(FriendActionSuccess(msg));
      add(LoadFriendsEvent());
    } catch (e) {
      emit(FriendError('Failed to respond: $e'));
    }
  }

  Future<void> _onRemove(RemoveFriendEvent event, Emitter<FriendState> emit) async {
    try {
      await _repository.removeFriend(event.friendId);
      emit(FriendActionSuccess('Friend removed.'));
      add(LoadFriendsEvent());
    } catch (e) {
      emit(FriendError('Failed to remove friend: $e'));
    }
  }
}
