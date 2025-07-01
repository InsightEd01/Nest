import 'package:eschool/ui/widgets/noticeBoardContainer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NoticeBoardScreen extends StatelessWidget {
  final int? childId;
  const NoticeBoardScreen({super.key, this.childId});

  static Route route(RouteSettings routeSettings) {
    return CupertinoPageRoute(builder: (_) => const NoticeBoardScreen());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: NoticeBoardContainer(
        showBackButton: true,
      ),
    );
  }
}
