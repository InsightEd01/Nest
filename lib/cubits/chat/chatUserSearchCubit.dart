import 'package:eschool/data/models/chatUser.dart';
import 'package:eschool/data/repositories/chatRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/*
This cubit will handle child and parents searched chat users
*/

abstract class ChatUsersSearchState {}

class ChatUsersSearchInitial extends ChatUsersSearchState {}

class ChatUsersSearchFetchInProgress extends ChatUsersSearchState {}

class ChatUsersSearchFetchFailure extends ChatUsersSearchState {
  final String errorMessage;

  ChatUsersSearchFetchFailure({required this.errorMessage});
}

class ChatUsersSearchFetchSuccess extends ChatUsersSearchState {
  final List<ChatUser> chatUsers;
  final int totalOffset;
  final bool moreChatUserFetchError;
  final bool moreChatUserFetchProgress;

  ChatUsersSearchFetchSuccess({
    required this.chatUsers,
    required this.totalOffset,
    required this.moreChatUserFetchError,
    required this.moreChatUserFetchProgress,
  });

  ChatUsersSearchFetchSuccess copyWith({
    List<ChatUser>? newChatUsers,
    int? newTotalOffset,
    bool? newFetchMorechatUsersInProgress,
    bool? newFetchMorechatUsersError,
  }) {
    return ChatUsersSearchFetchSuccess(
      chatUsers: newChatUsers ?? chatUsers,
      totalOffset: newTotalOffset ?? totalOffset,
      moreChatUserFetchProgress:
          newFetchMorechatUsersInProgress ?? moreChatUserFetchProgress,
      moreChatUserFetchError:
          newFetchMorechatUsersError ?? moreChatUserFetchError,
    );
  }
}

class ChatUsersSearchCubit extends Cubit<ChatUsersSearchState> {
  final ChatRepository _chatRepository;

  ChatUsersSearchCubit(this._chatRepository) : super(ChatUsersSearchInitial());

  Future<void> fetchChatUsers(
      {required bool isParent, required String searchString,}) async {
    emit(ChatUsersSearchFetchInProgress());
    try {
      final Map<String, dynamic> data = await _chatRepository.fetchChatUsers(
        offset: 0,
        searchString: searchString,
        isParent: isParent,
      );
      return emit(ChatUsersSearchFetchSuccess(
        chatUsers: data['chatUsers'],
        totalOffset: data['totalItems'],
        moreChatUserFetchError: false,
        moreChatUserFetchProgress: false,
      ),);
    } catch (e) {
      emit(
        ChatUsersSearchFetchFailure(
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> fetchMoreChatUsers(
      {required bool isParent, required String searchString,}) async {
    if (state is ChatUsersSearchFetchSuccess) {
      final stateAs = state as ChatUsersSearchFetchSuccess;
      if (stateAs.moreChatUserFetchProgress) {
        return;
      }
      try {
        emit(stateAs.copyWith(newFetchMorechatUsersInProgress: true));

        final Map moreTransactionResult = await _chatRepository.fetchChatUsers(
          offset: stateAs.chatUsers.length,
          isParent: isParent,
          searchString: searchString,
        );

        final List<ChatUser> chatUsers = stateAs.chatUsers;

        chatUsers.addAll(moreTransactionResult['chatUsers']);

        emit(
          ChatUsersSearchFetchSuccess(
            chatUsers: chatUsers,
            totalOffset: moreTransactionResult['totalItems'],
            moreChatUserFetchError: false,
            moreChatUserFetchProgress: false,
          ),
        );
      } catch (e) {
        emit(
          (state as ChatUsersSearchFetchSuccess).copyWith(
            newFetchMorechatUsersInProgress: false,
            newFetchMorechatUsersError: true,
          ),
        );
      }
    }
  }

  bool hasMore() {
    if (state is ChatUsersSearchFetchSuccess) {
      return (state as ChatUsersSearchFetchSuccess).chatUsers.length <
          (state as ChatUsersSearchFetchSuccess).totalOffset;
    }
    return false;
  }

  void emitInit() {
    emit(ChatUsersSearchInitial());
  }
}
