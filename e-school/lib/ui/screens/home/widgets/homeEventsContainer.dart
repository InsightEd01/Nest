import 'package:eschool/app/routes.dart';
import 'package:eschool/data/models/event.dart';
import 'package:eschool/ui/widgets/listItemForEvents.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/uiUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeEventsContainer extends StatelessWidget {
  final bool animate;
  final List<Event> events;
  const HomeEventsContainer({
    super.key,
    this.animate = true,
    required this.events,
  });

  Widget _eventsSuccessItems(List<Event> events) {
    return Column(
      children: List.generate(
        events.length,
        (index) => Animate(
          effects: animate
              ? listItemAppearanceEffects(
                  itemIndex: index,
                  totalLoadedItems: events.length,
                )
              : null,
          child: EventItemContainer(
            event: events[index],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width *
            UiUtils.screenContentHorizontalPaddingInPercentage,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                UiUtils.getTranslatedLabel(context, eventsKey),
                style: TextStyle(
                  color: UiUtils.getColorScheme(context).secondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.start,
              ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.academicCalendar,
                    arguments: {'hasBack': true},
                  );
                },
                child: Text(
                  UiUtils.getTranslatedLabel(context, viewAllKey),
                  style: TextStyle(
                    color: UiUtils.getColorScheme(context).onSurface,
                    fontSize: 13.0,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * (0.025),
          ),
          _eventsSuccessItems(events),
          SizedBox(
            height: MediaQuery.of(context).size.height * (0.025),
          ),
        ],
      ),
    );
  }
}
