import 'package:flutter/material.dart';

import '../../../core/constants/showcase_constants.dart';
import '../view_models/showcase_view_model.dart';
import 'screens/buttons.dart';
import 'screens/color_palettes_screen.dart';
import 'screens/component_screen.dart';
import 'screens/elevation_screen.dart';
import 'screens/typography_screen.dart';
import 'navigation_transition_view.dart';
import 'one_two_transition_view.dart';
import 'widgets/expanded_trailing_actions.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.useMaterial3, required this.viewModel});

  final bool useMaterial3;
  final ShowcaseViewModel viewModel;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController controller;
  late final CurvedAnimation railAnimation;
  bool controllerInitialized = false;
  bool showMediumSizeLayout = false;
  bool showLargeSizeLayout = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: Duration(milliseconds: transitionLength.toInt() * 2),
      value: 0,
      vsync: this,
    );
    railAnimation = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.5, 1.0),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final double width = MediaQuery.of(context).size.width;
    final AnimationStatus status = controller.status;
    if (width > mediumWidthBreakpoint) {
      if (width > largeWidthBreakpoint) {
        showMediumSizeLayout = false;
        showLargeSizeLayout = true;
      } else {
        showMediumSizeLayout = true;
        showLargeSizeLayout = false;
      }
      if (status != AnimationStatus.forward &&
          status != AnimationStatus.completed) {
        controller.forward();
      }
    } else {
      showMediumSizeLayout = false;
      showLargeSizeLayout = false;
      if (status != AnimationStatus.reverse &&
          status != AnimationStatus.dismissed) {
        controller.reverse();
      }
    }
    if (!controllerInitialized) {
      controllerInitialized = true;
      controller.value = width > mediumWidthBreakpoint ? 1 : 0;
    }
  }

  Widget createScreenFor(
    ScreenSelected screenSelected,
    bool showNavBarExample,
  ) => switch (screenSelected) {
    ScreenSelected.component => Expanded(
      child: OneTwoTransition(
        animation: railAnimation,
        one: FirstComponentList(
          showNavBottomBar: showNavBarExample,
          scaffoldKey: scaffoldKey,
          showSecondList: showMediumSizeLayout || showLargeSizeLayout,
        ),
        two: SecondComponentList(scaffoldKey: scaffoldKey),
      ),
    ),
    ScreenSelected.color => const ColorPalettesScreen(),
    ScreenSelected.typography => const TypographyScreen(),
    ScreenSelected.elevation => const ElevationScreen(),
  };

  PreferredSizeWidget _createAppBar() {
    return AppBar(
      title: widget.useMaterial3
          ? const Text('Material 3')
          : const Text('Material 2'),
      actions: !showMediumSizeLayout && !showLargeSizeLayout
          ? const []
          : [Container()],
    );
  }

  Widget _trailingActions() => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Flexible(
        child: ColorSeedButton(
          handleColorSelect: widget.viewModel.selectColor,
          colorSelected: widget.viewModel.colorSelected,
          colorSelectionMethod: widget.viewModel.colorSelectionMethod,
        ),
      ),
      Flexible(
        child: ColorImageButton(
          handleImageSelect: widget.viewModel.selectImage,
          imageSelected: widget.viewModel.imageSelected,
          colorSelectionMethod: widget.viewModel.colorSelectionMethod,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, widget.viewModel]),
      builder: (context, child) {
        return NavigationTransition(
          scaffoldKey: scaffoldKey,
          animationController: controller,
          railAnimation: railAnimation,
          appBar: _createAppBar(),
          body: createScreenFor(
            ScreenSelected.values[widget.viewModel.selectedScreenIndex],
            controller.value == 1,
          ),
          navigationRail: NavigationRail(
            extended: showLargeSizeLayout,
            destinations: _navRailDestinations,
            selectedIndex: widget.viewModel.selectedScreenIndex,
            onDestinationSelected: widget.viewModel.selectScreen,
            trailing: Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: showLargeSizeLayout
                    ? ExpandedTrailingActions(
                        handleImageSelect: widget.viewModel.selectImage,
                        handleColorSelect: widget.viewModel.selectColor,
                        colorSelectionMethod:
                            widget.viewModel.colorSelectionMethod,
                        imageSelected: widget.viewModel.imageSelected,
                        colorSelected: widget.viewModel.colorSelected,
                      )
                    : _trailingActions(),
              ),
            ),
          ),
          navigationBar: NavigationBars(
            onSelectItem: widget.viewModel.selectScreen,
            selectedIndex: widget.viewModel.selectedScreenIndex,
            isExampleBar: false,
          ),
        );
      },
    );
  }
}

final List<NavigationRailDestination> _navRailDestinations = appBarDestinations
    .map(
      (destination) => NavigationRailDestination(
        icon: Tooltip(message: destination.label, child: destination.icon),
        selectedIcon: Tooltip(
          message: destination.label,
          child: destination.selectedIcon,
        ),
        label: Text(destination.label),
      ),
    )
    .toList(growable: false);
