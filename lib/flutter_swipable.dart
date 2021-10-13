library swipe_card;

import 'dart:async';

import 'package:flutter/material.dart';

import 'dart:math' as math;

class Swipable extends StatefulWidget {
  /// @param child [Widget]
  /// @required
  /// Swipable content.
  final Widget? child;

  /// Callback
  /// Hook triggered when the card starts being dragged.
  /// @param details [DragStartDetails]
  final void Function(DragStartDetails details)? onSwipeStart;

  /// Callback
  /// Hook triggered when the card position changes.
  /// @param details [DragUpdateDetails]
  final void Function(DragUpdateDetails details)? onPositionChanged;

  /// Callback
  /// Hook triggered when the card stopped being dragged and doesn't meet the requirement to be swiped.
  /// @param details [DragEndDetails]
  final void Function(Offset position, DragEndDetails details)? onSwipeCancel;

  /// Callback
  /// Hook triggered when the card stopped being dragged and meets the requirement to be swiped.
  /// @param details [DragEndDetails]
  final void Function(Offset position, DragEndDetails details)? onSwipeEnd;

  /// Callback
  /// Hook triggered when the card finished swiping right.
  /// @param finalPosition [Offset]
  final void Function(Offset finalPosition)? onSwipeRight;

  /// Callback
  /// Hook triggered when the card finished swiping left.
  /// @param finalPosition [Offset]
  final void Function(Offset finalPosition)? onSwipeLeft;

  /// Callback
  /// Hook triggered when the card finished swiping up.
  /// @param finalPosition [Offset]
  final void Function(Offset finalPosition)? onSwipeUp;

  /// Callback
  /// Hook triggered when the card finished swiping down.
  /// @param finalPosition [Offset]
  final void Function(Offset finalPosition)? onSwipeDown;

  /// @param swipe [Stream<double>]
  /// Triggers an automatic swipe.
  /// Cancels automatically after first emission.R
  /// The double value sent corresponds to the direction the card should follow (clockwise radian angle).
  final Stream<double>? swipe;

  /// @param animationDuration [int]
  /// Animation duration (in milliseconds) for the card to swipe atuomatically or get back to its original position on swipe cancel.
  final int? animationDuration;

  /// @param animationCurve [Curve]
  /// Animation timing function.
  final Curve? animationCurve;

  /// @param threshold [double]
  /// Defines the strength needed for a card to be swiped.
  /// The bigger, the easier it is to swipe.
  final double? threshold;

  /// @param horizontalSwipe [bool]
  /// To enable or disable the swipe in horizontal direction.
  /// defaults to true.
  final bool horizontalSwipe;

  /// @param verticalSwipe [bool]
  /// To enable or disable the swipe in vertical direction.
  /// defaults to true.
  final bool verticalSwipe;

  Swipable({
    Key? key,
    @required this.child,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.onSwipeDown,
    this.onSwipeUp,
    this.onPositionChanged,
    this.onSwipeStart,
    this.onSwipeCancel,
    this.onSwipeEnd,
    this.swipe,
    this.animationDuration = 300,
    this.animationCurve = Curves.easeInOut,
    this.horizontalSwipe = true,
    this.verticalSwipe = true,
    this.threshold = 0.3,
  }): super(key: key);

  @override
  SwipableState createState() => SwipableState();
}

class SwipableState extends State<Swipable> {
  double _positionY = 0;
  double _positionX = 0;

  int _duration = 0;

  StreamSubscription? _swipeSub;

  @override
  void initState() {
    super.initState();

    _swipeSub = widget.swipe?.listen((angle) {
      _swipeSub?.cancel();
      _animate(angle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
            onPanStart: _onPanStart,
            onPanEnd: _onPanEnd,
            onPanUpdate: _onPanUpdate,
            child: Stack(overflow: Overflow.visible, children: [
              AnimatedPositioned(
                  duration: Duration(milliseconds: _duration),
                  top: _positionY,
                  left: _positionX,
                  child: Container(
                      constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight,
                          maxWidth: constraints.maxWidth),
                      child: widget.child))
            ])));
  }

  @override
  void dispose() {
    super.dispose();

    _swipeSub?.cancel();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _positionX += details.delta.dx;
      _positionY += details.delta.dy;
    });

    if(widget.onPositionChanged != null) widget.onPositionChanged!(details);
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _duration = 0;
    });

    if(widget.onSwipeStart != null) widget.onSwipeStart!(details);
  }

  void _onPanEnd(DragEndDetails details) {
    double newX = 0;
    double newY = 0;

    // Get screen dimensions.
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    double potentialX = _positionX +
        (details.velocity.pixelsPerSecond.dx * (widget.threshold ?? 1));
    double potentialY = _positionY +
        (details.velocity.pixelsPerSecond.dy * (widget.threshold ?? 1));

    Offset currentPosition = Offset(_positionX, _positionY);

    bool shouldSwipe = potentialX.abs() >= width || potentialY.abs() >= height;

    double angle = details.velocity.pixelsPerSecond.direction;

    //<=45 deg 1 quad to >=315 deg 4 quad
    bool swipedRight = angle.abs() <= (math.pi / 4);
    // As the angle is not continous as it breaks after 360 deg
    //  || angle.abs() >= (7 * math.pi / 4);

    //>=135 deg 2 quad to <=225 deg 3 quad
    bool swipedLeft =
        angle.abs() >= (3 * math.pi / 4) && angle.abs() <= (5 * math.pi / 4);
    //<135 deg 2 quad to >45 deg 1 quad
    bool swipedUp =
        angle.abs() < (3 * math.pi / 4) && angle.abs() > (math.pi / 4);
    //>225 deg 2 quad to <315 deg 1 quad
    bool swipedDown =
        angle.abs() > (5 * math.pi / 4) && angle.abs() < (7 * math.pi / 4);

    bool movingVertically = swipedUp || swipedDown;
    bool movingHorizontally = swipedRight || swipedLeft;

    //either it will be moving vertically or horizontally but not both
    if (movingVertically && !widget.verticalSwipe) shouldSwipe = false;
    if (movingHorizontally && !widget.horizontalSwipe) shouldSwipe = false;
    if (shouldSwipe) {
      // horizontal speed or vertical speed is enough to make the card disappear in _duration ms.
      newX = potentialX;
      newY = potentialY;
      widget.onSwipeEnd?.call(currentPosition, details);
    } else {
      newX = 0;
      newY = 0;

      widget.onSwipeCancel?.call(currentPosition, details);
    }

    setState(() {
      _positionX = newX;
      _positionY = newY;
      _duration = widget.animationDuration ?? 300;
    });

    if (shouldSwipe) {
      Future.delayed(Duration(milliseconds: widget.animationDuration ?? 300),
          () {
        // Clock wise radian angle of the velocity

        Offset finalPosition = Offset(newX, newY);
        if (swipedRight && widget.onSwipeRight != null) {
          widget.onSwipeRight!(finalPosition);
        } else if (swipedLeft && widget.onSwipeLeft != null) {
          widget.onSwipeLeft!(finalPosition);
        } else if (swipedDown && widget.onSwipeDown != null) {
          widget.onSwipeDown!(finalPosition);
        } else if (swipedUp && widget.onSwipeUp != null) {
          widget.onSwipeUp!(finalPosition);
        }
      });
    }
  }

  void _animate(double angle) {
    if (angle < -math.pi || angle > math.pi) {
      throw ('Angle must be between -π and π (inclusive).');
    }

    if (widget.onSwipeStart != null) {
      widget.onSwipeStart!(DragStartDetails());
    }

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    // Horizontal distance to arrive to the final X.
    double remainingX;
    // Vertical distance to arrive to the final Y.
    double remainingY;

    if (angle.abs() <= math.pi / 4) {
      // Swiping right
      remainingX = width - _positionX;
      remainingY = 0;
    } else if (angle.abs() > 3 * math.pi / 4) {
      // Swiping left
      remainingX = -width - _positionX;
      remainingY = 0;
    } else if (angle >= 0) {
      // Swiping down
      remainingX = 0;
      remainingY = height - _positionY;
    } else {
      // Swiping up
      remainingX = 0;
      remainingY = -height - _positionY;
    }

    // Calculating velocity so the card arrives at it's final position when the animation ends.
    Velocity velocity = Velocity(
        pixelsPerSecond: Offset(remainingX / (widget.threshold ?? 1),
            remainingY / (widget.threshold ?? 1)));
    DragEndDetails details = DragEndDetails(velocity: velocity);
    _onPanEnd(details);
  }
}
