library flutter_custom_tab_bar;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_custom_tab_bar/library.dart';

final Duration kCustomerTabBarAnimDuration = Duration(milliseconds: 300);

typedef IndexedTabBarItemBuilder = Widget Function(
    BuildContext context, int index);

class CustomTabBarContext extends InheritedWidget {
  final ValueNotifier<ScrollProgressInfo> progressNotifier =
      ValueNotifier(ScrollProgressInfo());

  CustomTabBarContext({required Widget child, Key? key})
      : super(child: child, key: key);

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  static CustomTabBarContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CustomTabBarContext>(
        aspect: CustomTabBarContext);
  }
}

class CustomTabBar extends StatelessWidget {
  final Axis direction;
  final IndexedTabBarItemBuilder builder;
  final int itemCount;
  final PageController pageController;
  final CustomIndicator? indicator;
  final ValueChanged<int>? onTapItem;
  final double? height;
  final double? width;
  final bool pinned;
  final bool controlJump;
  final CustomTabBarController? tabBarController;
  const CustomTabBar(
      {required this.builder,
      required this.itemCount,
      required this.pageController,
      this.height,
      this.direction = Axis.horizontal,
      this.onTapItem,
      this.indicator,
      this.tabBarController,
      this.width,
      this.pinned = false,
      this.controlJump = true,
      Key? key})
      : assert(pinned == true || (pinned == false && height != null)),
        assert(direction == Axis.horizontal ||
            (direction == Axis.vertical && width != null)),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTabBarContext(
        child: _CustomTabBar(
            direction: direction,
            onTapItem: onTapItem,
            controlJump: controlJump,
            indicator: indicator,
            tabBarController: tabBarController,
            width: width,
            height: height,
            pinned: pinned,
            builder: builder,
            itemCount: itemCount,
            pageController: pageController));
  }
}

class _CustomTabBar extends StatefulWidget {
  final IndexedTabBarItemBuilder builder;
  final int itemCount;
  final PageController pageController;
  final CustomIndicator? indicator;
  final ValueChanged<int>? onTapItem;
  final double? height;
  final double? width;
  final bool pinned;
  final bool controlJump;
  final CustomTabBarController? tabBarController;
  final Axis direction;

  const _CustomTabBar(
      {required this.builder,
      required this.itemCount,
      required this.pageController,
      this.direction = Axis.horizontal,
      this.height,
      this.onTapItem,
      this.tabBarController,
      this.controlJump = true,
      this.indicator,
      this.width,
      this.pinned = false,
      Key? key})
      : super(key: key);

  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<_CustomTabBar>
    with TickerProviderStateMixin {
  late List<Size> sizeList =
      List.generate(widget.itemCount, (index) => Size(0, 0));
  ScrollController? _scrollController;
  late CustomTabBarController _tabBarController =
      widget.tabBarController ?? CustomTabBarController();
  late int _currentIndex = widget.pageController.initialPage;
  ValueNotifier<IndicatorPosition> positionNotifier =
      ValueNotifier(IndicatorPosition(0, 0, 0, 0));
  late ValueNotifier<ScrollProgressInfo>? progressNotifier =
      CustomTabBarContext.of(context)?.progressNotifier;
  double get getCurrentPage => widget.pageController.page ?? 0;

  double indicatorLeft = 0;
  double indicatorRight = 0;
  double indicatorTop = 0;
  double indicatorBottom = 0;

  void _init() {
    _tabBarController.setOrientation(widget.direction);
    _tabBarController.setAnimateToIndexCallback(_animateToIndex);
    widget.indicator?.controller = _tabBarController;
  }

  @override
  void didUpdateWidget(covariant _CustomTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _init();
  }

  @override
  void initState() {
    super.initState();

    _init();

    positionNotifier.addListener(() {
      setState(() {
        indicatorLeft =
            positionNotifier.value.left + (widget.indicator?.left ?? 0);
        indicatorRight =
            positionNotifier.value.right + (widget.indicator?.right ?? 0);
        indicatorTop =
            positionNotifier.value.top + (widget.indicator?.top ?? 0);
        indicatorBottom =
            positionNotifier.value.bottom + (widget.indicator?.bottom ?? 0);
      });
    });

    Future.delayed(Duration.zero, () {
      progressNotifier?.value = ScrollProgressInfo(currentIndex: _currentIndex);
    });

    if (!widget.pinned) {
      _scrollController = ScrollController();
    }

    widget.pageController.addListener(() {
      if (_tabBarController.isJumpToTarget) return;
      if (_currentIndex == getCurrentPage) return;
      _currentIndex = getCurrentPage.toInt();

      // _tabBarController.scrollByPageView(getViewportWidth() / 2, sizeList,
      //     _scrollController, widget.pageController);

      _tabBarController.scrollByPageView(getViewportSize() / 2, sizeList,
          _scrollController, widget.pageController);

      ScrollProgressInfo? scrollProgressInfo =
          _tabBarController.calculateScrollProgressByPageView(
              _currentIndex, widget.pageController);
      if (scrollProgressInfo != null) {
        progressNotifier?.value = scrollProgressInfo;
      }

      widget.indicator?.updateScrollIndicator(getCurrentPage, sizeList,
          kCustomerTabBarAnimDuration, positionNotifier);
    });
  }

  // double getViewportWidth() {
  //   if (widget.width != null) {
  //     return widget.width!;
  //   }

  //   if (_viewportWidth == 0) {
  //     return MediaQuery.of(context).size.width;
  //   }
  //   return _viewportWidth;
  // }

  // double _viewportWidth = 0;
  // double? getViewportHeight() {
  //   if (widget.pinned) {
  //     return null;
  //   }
  //   return widget.height;
  // }

  Size _viewportSize = Size(-1, -1);
  Size getViewportSize() {
    double width = -1;
    if (widget.width != null) {
      // return widget.width!;
      width = widget.width!;
    } else if (_viewportSize.width == -1) {
      width = MediaQuery.of(context).size.width;
    } else {
      width = _viewportSize.width;
    }

    double height = -1;

    if (widget.pinned) {
      // return null;
      height = -1;
    } else {
      height = widget.height ?? -1;
    }

    _viewportSize = Size(width, height);
    return _viewportSize;
    // return Size(width, height);
    // return widget.height;
  }

  @override
  void dispose() {
    super.dispose();
    progressAnimationController?.stop(canceled: true);
  }

  @override
  Widget build(BuildContext context) {
    late Widget child;
    if (widget.pinned && widget.direction == Axis.horizontal) {
      child = _buildTabBarItemList();
    } else {
      Widget scrollableWidget = Scrollable(
        controller: _scrollController,
        viewportBuilder: _buildViewport,
        axisDirection: widget.direction == Axis.horizontal
            ? AxisDirection.right
            : AxisDirection.down,
        physics: widget.pinned
            ? NeverScrollableScrollPhysics()
            : BouncingScrollPhysics(),
      );

      if (widget.direction == Axis.horizontal) {
        child = MeasureSizeBox(
            onSizeCallback: (size) {
              // _viewportWidth = size.width;
              // _viewportSize.width = size.width;
              _viewportSize = Size(size.width, _viewportSize.height);
            },
            child: scrollableWidget);
      } else {
        child = scrollableWidget;
      }
    }

    // return Container(
    //     height: getViewportHeight(), width: getViewportWidth(), child: child);

    // print(_viewportSize.width);
    // print(_viewportSize.height);
    return Container(
        width: getViewportSize().width == -1 ? null : _viewportSize.width,
        height: getViewportSize().height == -1 ? null : _viewportSize.height,
        child: child);
  }

  Widget _buildViewport(BuildContext context, ViewportOffset offset) {
    return Viewport(
      offset: offset,
      axisDirection: widget.direction == Axis.horizontal
          ? AxisDirection.right
          : AxisDirection.down,
      slivers: [_buildSlivers()],
    );
  }

  ///点击tabbar Item
  void _onTapItem(int index) {
    if (_currentIndex == index) return;
    widget.onTapItem?.call(index);
    _animateToIndex(index);
  }

  void _animateToIndex(int index) {
    if (_currentIndex == index) return;
    _tabBarController.setCurrentIndex(index);
    _tabBarController.startJump();
    if (widget.controlJump) {
      widget.pageController.animateToPage(index,
          duration: kCustomerTabBarAnimDuration, curve: Curves.easeIn);
    }
    updateProgressByAnimation(_currentIndex, index);
    _tabBarController.scrollTargetToCenter(
        // getViewportWidth() / 2, index, sizeList, _scrollController,
        getViewportSize() / 2,
        index,
        sizeList,
        _scrollController,
        duration: kCustomerTabBarAnimDuration);

    widget.indicator?.indicatorScrollToIndex(
        index, sizeList, kCustomerTabBarAnimDuration, this, positionNotifier);

    _currentIndex = index;
  }

  AnimationController? progressAnimationController;
  Animation? progressAnimation;

  ///通过动画更新进度
  void updateProgressByAnimation(int currentIndex, int targetIndex) {
    progressAnimationController =
        AnimationController(vsync: this, duration: kCustomerTabBarAnimDuration);
    Animation animation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(progressAnimationController!);

    animation.addListener(() {
      if (!mounted) return null;
      progressNotifier!.value = ScrollProgressInfo(
          progress: animation.value,
          currentIndex: currentIndex,
          targetIndex: targetIndex);
    });
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tabBarController.endJump();
      }
    });
    progressAnimationController?.forward();
  }

  ///是否已经测量TabBarItem的size
  bool isMeasureTabBarItemSize() {
    for (int i = 0; i < sizeList.length; i++) {
      if (sizeList[i].width == 0) {
        return false;
      }
    }

    return true;
  }

  //构建指示器
  Widget _buildIndicator() {
    if (!isMeasureTabBarItemSize()) return SizedBox();
    return Positioned(
      key: widget.key,
      left: indicatorLeft,
      right: indicatorRight,
      top: indicatorTop,
      bottom: indicatorBottom,
      child: Container(
        width: widget.indicator?.width,
        height: widget.indicator?.height,
        decoration: BoxDecoration(
          color: widget.indicator?.color,
          borderRadius: widget.indicator?.radius,
        ),
      ),
    );
  }

  Widget _buildTabBarItemList() {
    return Stack(children: [
      if (widget.indicator != null) _buildIndicator(),
      TabBarItemList(
        direction: widget.direction,
        viewPortWidth: widget.pinned
            ? (getViewportSize().width == -1 ? null : _viewportSize.width)
            : null,
        physics: widget.pinned
            ? NeverScrollableScrollPhysics()
            : BouncingScrollPhysics(),
        builder: widget.builder,
        onTapItem: _onTapItem,
        itemCount: widget.itemCount,
        sizeList: sizeList,
        onMeasureCompleted: () {
          WidgetsBinding.instance?.addPostFrameCallback((d) {
            setState(() {
              widget.indicator?.updateScrollIndicator(getCurrentPage, sizeList,
                  kCustomerTabBarAnimDuration, positionNotifier);

              _tabBarController.scrollTargetToCenter(
                  getViewportSize() / 2,
                  widget.pageController.initialPage,
                  sizeList,
                  _scrollController);
            });
          });
        },
      )
    ]);
  }

  Widget _buildSlivers() {
    return SliverList(
        delegate: SliverChildListDelegate([_buildTabBarItemList()]));
  }
}

class TabBarItemList extends StatefulWidget {
  final Axis direction;
  final double? viewPortWidth;
  final int itemCount;
  final IndexedWidgetBuilder builder;
  final List<Size> sizeList;
  final ValueChanged<int> onTapItem;
  final ScrollPhysics physics;
  final VoidCallback onMeasureCompleted;

  TabBarItemList(
      {required this.viewPortWidth,
      required this.itemCount,
      required this.builder,
      required this.sizeList,
      required this.onTapItem,
      required this.physics,
      required this.onMeasureCompleted,
      required this.direction,
      key})
      : super(key: key);

  @override
  TabBarItemListState createState() => TabBarItemListState();
}

class TabBarItemListState extends State<TabBarItemList> {
  bool isMeasureCompletedCallback = false;

  Widget _createItem(int index, Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onTapItem(index),
      child: child,
    );
  }

  bool isAllItemMeasureComplete() {
    for (Size size in widget.sizeList) {
      if (size.isEmpty) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetList = [];

    ///如果不能滑动并且是水平方向就平分父级组件宽度
    if (widget.physics is NeverScrollableScrollPhysics &&
        widget.direction == Axis.horizontal) {
      double? itemWidth = (widget.viewPortWidth ?? 0) / widget.itemCount;
      for (var i = 0; i < widget.itemCount; i++) {
        widgetList.add(_createItem(
            i,
            Container(
              width: itemWidth,
              child: widget.builder(context, i),
            )));
        widget.sizeList[i] = Size(itemWidth, 0);
      }
      if (!isMeasureCompletedCallback) {
        widget.onMeasureCompleted();
        isMeasureCompletedCallback = true;
      }
    } else {
      for (var i = 0; i < widget.itemCount; i++) {
        widgetList.add(_createItem(
            i,
            MeasureSizeBox(
              child: widget.builder(context, i),
              onSizeCallback: (size) {
                widget.sizeList[i] = size;
                if (isAllItemMeasureComplete() && !isMeasureCompletedCallback) {
                  widget.onMeasureCompleted();
                  isMeasureCompletedCallback = true;
                }
              },
            )));
      }
    }

    if (widget.direction == Axis.horizontal) {
      return Row(children: widgetList);
    }

    return Container(
        width: widget.viewPortWidth, child: Column(children: widgetList));
  }
}

class MeasureSizeBox extends SingleChildRenderObjectWidget {
  final Widget child;
  final ValueChanged<Size> onSizeCallback;

  MeasureSizeBox({
    required this.child,
    required this.onSizeCallback,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderConstrainedBox(onSizeCallback: this.onSizeCallback);
  }
}

class _RenderConstrainedBox extends RenderConstrainedBox {
  final ValueChanged<Size> onSizeCallback;

  _RenderConstrainedBox({required this.onSizeCallback})
      : super(additionalConstraints: BoxConstraints());

  @override
  void layout(Constraints constraints, {bool parentUsesSize = false}) {
    super.layout(constraints, parentUsesSize: parentUsesSize);
    print(size);
    if (size.isEmpty) return;

    onSizeCallback(Size.copy(size));
  }
}

class TabBarItem extends StatefulWidget {
  final Widget? child;
  final int index;
  final TabBarTransform? transform;
  TabBarItem({
    Key? key,
    this.child,
    required this.index,
    this.transform,
  }) : super(key: key);

  @override
  _TabBarItemState createState() => _TabBarItemState();
}

class _TabBarItemState extends State<TabBarItem> {
  ValueNotifier<ScrollProgressInfo>? progressNotifier;
  ScrollProgressInfo? info;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      progressNotifier = CustomTabBarContext.of(context)?.progressNotifier;
      setState(() {
        info = progressNotifier!.value;
      });
      progressNotifier?.addListener(() {
        setState(() {
          info = progressNotifier!.value;
        });
      });
      assert(progressNotifier != null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (info == null) return SizedBox();
    if (widget.transform != null) {
      return widget.transform!.build(context, widget.index, info!);
    }

    return Container(
      child: widget.child,
    );
  }
}
