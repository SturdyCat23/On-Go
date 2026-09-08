import 'package:flutter/material.dart';

import 'theme_controller.dart';

/// The Warm Filter slider, shared by both front ends.
///
/// Smooth and continuous: no division ticks, no fixed steps, and every value
/// between 0 and [ThemeController.maxWarmFilter] is reachable. The thumb
/// follows the pointer exactly because the level it draws is itself a
/// continuous number — [ThemeController.warmFilter] — rather than a whole
/// step the slider has to round to.
///
/// Dragging writes straight through to the controller, so the readout and the
/// tint over the whole app update on the same frame as the thumb. Storage is
/// the one thing deferred: mid-drag values pass `save: false`, and the level
/// is written once when the drag ends, so a single sweep is one write rather
/// than one per frame.
///
/// Only the slider lives here. Each app keeps its own heading, readout and
/// [SliderTheme] — the design system shares colours and behaviour, not
/// density.
class WarmFilterSlider extends StatelessWidget {
  const WarmFilterSlider({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    // Listens in its own right, so the thumb tracks the level even where the
    // surrounding screen would not have rebuilt on its own.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Slider(
        value: controller.warmFilter.clamp(0.0, ThemeController.maxWarmFilter),
        min: 0,
        max: ThemeController.maxWarmFilter,
        // No `divisions`: that is what drew the tick dots and snapped the
        // thumb from notch to notch.
        onChanged: (v) => controller.setWarmFilter(v, save: false),
        onChangeEnd: controller.setWarmFilter,
      ),
    );
  }
}
