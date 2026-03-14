import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/stream_models.dart';
import '../../data/repositories/stream_repository.dart';

// --- EVENTS ---

abstract class StreamEvent {}

class StartStreamEvent extends StreamEvent {
  final String deviceId;
  final String channelId;
  final String streamType;
  final String sdpOffer;

  StartStreamEvent({
    required this.deviceId,
    required this.channelId,
    required this.streamType,
    required this.sdpOffer,
  });
}

class HeartbeatEvent extends StreamEvent {
  final String sessionId;
  HeartbeatEvent(this.sessionId);
}

class StopStreamEvent extends StreamEvent {
  final String sessionId;
  StopStreamEvent(this.sessionId);
}

// --- STATES ---

abstract class StreamState {}

class StreamInitial extends StreamState {}

class StreamConnecting extends StreamState {}

class StreamActive extends StreamState {
  final String sdpAnswer;
  final String sessionId;

  StreamActive({required this.sdpAnswer, required this.sessionId});
}

class StreamError extends StreamState {
  final String message;
  StreamError(this.message);
}

// --- BLOC ---

class StreamBloc extends Bloc<StreamEvent, StreamState> {
  final StreamRepository _repository;

  StreamBloc(this._repository) : super(StreamInitial()) {
    on<StartStreamEvent>(_onStartStream);
    on<HeartbeatEvent>(_onHeartbeat);
    on<StopStreamEvent>(_onStopStream);
  }

  Future<void> _onStartStream(StartStreamEvent event, Emitter<StreamState> emit) async {
    emit(StreamConnecting());
    try {
      final request = LiveStreamRequest(
        sdpOffer: event.sdpOffer,
        streamType: event.streamType,
      );
      
      final response = await _repository.startLiveStream(
        event.deviceId, 
        event.channelId, 
        request
      );
      
      emit(StreamActive(
        sdpAnswer: response.sdpAnswer,
        sessionId: response.sessionId,
      ));
    } catch (e) {
      emit(StreamError(e.toString()));
    }
  }

  Future<void> _onHeartbeat(HeartbeatEvent event, Emitter<StreamState> emit) async {
    try {
      await _repository.sendHeartbeat(event.sessionId);
    } catch (e) {
      // We don't emit an error state here because a single failed heartbeat 
      // shouldn't instantly crash the player UI. It will try again in 30s.
    }
  }

  Future<void> _onStopStream(StopStreamEvent event, Emitter<StreamState> emit) async {
    try {
      await _repository.stopStream(event.sessionId);
      emit(StreamInitial());
    } catch (e) {
      emit(StreamError("Failed to cleanly stop stream: ${e.toString()}"));
    }
  }
}