import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/request_model.dart';

class RequestsViewModel extends Notifier<List<RequestModel>> {
  @override
  List<RequestModel> build() {
    return [
      RequestModel(id: '1', item: "Calculator", from: "Amit", status: "Pending"),
      RequestModel(id: '2', item: "Helmet", from: "You", status: "Accepted"),
    ];
  }

  void acceptRequest(String id) {
    state = [
      for (final request in state)
        if (request.id == id)
          RequestModel(
            id: request.id,
            item: request.item,
            from: request.from,
            status: "Accepted",
          )
        else
          request,
    ];
  }

  void declineRequest(String id) {
    state = state.where((r) => r.id != id).toList();
  }
}

// Provider
final requestsViewModelProvider = NotifierProvider<RequestsViewModel, List<RequestModel>>(RequestsViewModel.new);
