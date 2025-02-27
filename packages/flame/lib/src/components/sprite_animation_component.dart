import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/src/effects/provider_interfaces.dart';
import 'package:meta/meta.dart';

export '../sprite_animation.dart';

class SpriteAnimationComponent extends PositionComponent
    with HasPaint
    implements SizeProvider {
  /// The animation used by the component.
  SpriteAnimation? _animation;

  /// If the component should be removed once the animation has finished.
  /// Needs the animation to have `loop = false` to ever remove the component,
  /// since it will never finish otherwise.
  bool removeOnFinish;

  /// Whether the animation is paused or playing.
  bool playing;

  /// When set to true, the component is auto-resized to match the
  /// size of current animation sprite.
  bool _autoResize;

  /// Creates a component with an empty animation which can be set later
  SpriteAnimationComponent({
    SpriteAnimation? animation,
    bool? autoResize,
    this.removeOnFinish = false,
    this.playing = true,
    Paint? paint,
    super.position,
    Vector2? size,
    super.scale,
    super.angle,
    super.nativeAngle,
    super.anchor,
    super.children,
    super.priority,
  })  : assert(
          (size == null) == (autoResize ?? size == null),
          '''If size is set, autoResize should be false or size should be null when autoResize is true.''',
        ),
        _animation = animation,
        _autoResize = autoResize ?? size == null,
        super(size: size ?? animation?.getSprite().srcSize) {
    if (paint != null) {
      this.paint = paint;
    }

    /// Register a listener to differentiate between size modification done by
    /// external calls v/s the ones done by [_resizeToSprite].
    this.size.addListener(_handleAutoResizeState);
  }

  /// Creates a SpriteAnimationComponent from a [size], an [image] and [data].
  /// Check [SpriteAnimationData] for more info on the available options.
  ///
  /// Optionally [removeOnFinish] can be set to true to have this component be
  /// auto removed from the FlameGame when the animation is finished.
  SpriteAnimationComponent.fromFrameData(
    Image image,
    SpriteAnimationData data, {
    bool? autoResize,
    bool removeOnFinish = false,
    bool playing = true,
    Paint? paint,
    Vector2? position,
    Vector2? size,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    int? priority,
  }) : this(
          animation: SpriteAnimation.fromFrameData(image, data),
          autoResize: autoResize,
          removeOnFinish: removeOnFinish,
          playing: playing,
          paint: paint,
          position: position,
          size: size,
          scale: scale,
          angle: angle,
          anchor: anchor,
          priority: priority,
        );

  /// Returns current value of auto resize flag.
  bool get autoResize => _autoResize;

  /// Sets the given value of autoResize flag. Will update the [size]
  /// to fit srcSize of current sprite if set to  true.
  set autoResize(bool value) {
    _autoResize = value;
    _resizeToSprite();
  }

  /// This flag helps in detecting if the size modification is done by
  /// some external call vs [_autoResize]ing code from [_resizeToSprite].
  bool _isAutoResizing = false;

  /// Returns the [SpriteAnimation] used by this component.
  SpriteAnimation? get animation => _animation;

  /// Sets the given [value] as [SpriteAnimation] to be used.
  set animation(SpriteAnimation? value) {
    if (_animation != value) {
      _animation = value;
      _resizeToSprite();
    }
  }

  @mustCallSuper
  @override
  void render(Canvas canvas) {
    _animation?.getSprite().render(
          canvas,
          size: size,
          overridePaint: paint,
        );
  }

  @mustCallSuper
  @override
  void update(double dt) {
    if (playing) {
      _animation?.update(dt);
      _resizeToSprite();
    }
    if (removeOnFinish && (_animation?.done() ?? false)) {
      removeFromParent();
    }
  }

  /// Updates the size to current [animation] sprite's srcSize if
  /// [autoResize] is true.
  void _resizeToSprite() {
    if (_autoResize) {
      _isAutoResizing = true;
      if (_animation != null) {
        size.setFrom(_animation!.getSprite().srcSize);
      } else {
        size.setZero();
      }
      _isAutoResizing = false;
    }
  }

  /// Turns off [_autoResize]ing if a size modification is done by user.
  void _handleAutoResizeState() {
    if (_autoResize && (!_isAutoResizing)) {
      _autoResize = false;
    }
  }
}
