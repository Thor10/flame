import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> main() async {
  // Generate an image
  final image = await generateImage();

  group('SpriteAnimationComponent clone and reversed', () {
    test(
      'clone creates independent copy',
      () {
        final animation = SpriteAnimation.spriteList(
          List.filled(5, Sprite(image)),
          stepTime: 0.1,
          loop: false,
        );
        final copy = animation.clone();
        expect(copy.loop, animation.loop);

        animation.update(0.1);
        expect(animation.currentIndex, 1);
        expect(copy.currentIndex, 0);

        copy.update(0.2);
        expect(animation.currentIndex, 1);
        expect(copy.currentIndex, 2);
      },
    );
    test(
      'reversed creates independent copy',
      () {
        final animation = SpriteAnimation.spriteList(
          List.filled(5, Sprite(image)),
          stepTime: 0.1,
          loop: false,
        );
        final copy = animation.reversed();
        expect(copy.loop, animation.loop);

        animation.update(0.1);
        expect(animation.currentIndex, 1);
        expect(copy.currentIndex, 0);

        copy.update(0.2);
        expect(animation.currentIndex, 1);
        expect(copy.currentIndex, 2);
      },
    );
  });

  group('SpriteAnimationComponent removal', () {
    testWithFlameGame(
      'removeOnFinish is true and animation#loop is false',
      (game) async {
        final animation = SpriteAnimation.spriteList(
          [
            Sprite(image),
            Sprite(image),
          ],
          stepTime: 1,
          loop: false,
        );
        final component = SpriteAnimationComponent(
          animation: animation,
          removeOnFinish: true,
        );

        await game.ensureAdd(component);

        expect(game.children.length, 1);
        game.update(2);

        // runs a cycle to remove the component
        game.update(0.1);
        expect(game.children.length, 0);
      },
    );

    testWithFlameGame(
      'removeOnFinish is true and animation#loop is true',
      (game) async {
        final animation = SpriteAnimation.spriteList(
          [
            Sprite(image),
            Sprite(image),
          ],
          stepTime: 1,
          // ignore: avoid_redundant_argument_values
          loop: true,
        );
        final component = SpriteAnimationComponent(
          animation: animation,
          removeOnFinish: true,
        );

        await game.ensureAdd(component);

        expect(component.parent, game);
        expect(game.children.length, 1);

        game.update(2);
        expect(component.parent, game);

        // runs a cycle to remove the component, but failed
        game.update(0.1);
        expect(game.children.length, 1);
      },
    );

    testWithFlameGame(
      'removeOnFinish is false and animation#loop is false',
      (game) async {
        final animation = SpriteAnimation.spriteList(
          [
            Sprite(image),
            Sprite(image),
          ],
          stepTime: 1,
          loop: false,
        );
        final component = SpriteAnimationComponent(
          animation: animation,
          // ignore: avoid_redundant_argument_values
          removeOnFinish: false,
        );

        await game.ensureAdd(component);

        expect(component.parent, game);
        expect(game.children.length, 1);

        game.update(2);
        expect(component.parent, game);

        // runs a cycle to remove the component, but failed
        game.update(0.1);
        expect(game.children.length, 1);
      },
    );

    testWithFlameGame(
      'removeOnFinish is false and animation#loop is true',
      (game) async {
        final animation = SpriteAnimation.spriteList(
          [
            Sprite(image),
            Sprite(image),
          ],
          stepTime: 1,
          // ignore: avoid_redundant_argument_values
          loop: true,
        );
        final component = SpriteAnimationComponent(
          animation: animation,
          // ignore: avoid_redundant_argument_values
          removeOnFinish: false,
        );

        await game.ensureAdd(component);

        expect(component.parent, game);
        expect(game.children.length, 1);

        game.update(2);
        expect(component.parent, game);

        // runs a cycle to remove the component, but failed
        game.update(0.1);
        expect(game.children.length, 1);
      },
    );

    testWithFlameGame(
      "component isn't removed if it is not playing",
      (game) async {
        final animation = SpriteAnimation.spriteList(
          [
            Sprite(image),
            Sprite(image),
          ],
          stepTime: 1,
          loop: false,
        );
        final component = SpriteAnimationComponent(
          animation: animation,
          removeOnFinish: true,
          playing: false,
        );

        await game.ensureAdd(component);

        expect(component.parent, game);
        expect(game.children.length, 1);

        game.update(2);
        expect(component.parent, game);

        // runs a cycle to potentially remove the component
        game.update(0.1);
        expect(game.children.length, 1);
      },
    );
  });

  group('SpriteAnimation timing of animation frames', () {
    test('Can move to last frame programatically', () {
      // Non-looping animation, with the expected total duration of 0.500 s
      final animation = SpriteAnimation.spriteList(
        List.filled(5, Sprite(image)),
        stepTime: 0.1,
        loop: false,
      );
      var callbackInvoked = 0;
      animation.onComplete = () {
        callbackInvoked++;
      };
      animation.setToLast();
      expect(animation.currentIndex, 4);
      expect(animation.elapsed, 0.5);
      expect(animation.done(), true);
      expect(callbackInvoked, 1);
    });
    // See https://github.com/flame-engine/flame/issues/895
    testWithFlameGame('Last animation frame is not skipped', (game) async {
      // Non-looping animation, with the expected total duration of 0.500 s
      final animation = SpriteAnimation.spriteList(
        List.filled(5, Sprite(image)),
        stepTime: 0.1,
        loop: false,
      );
      var callbackInvoked = 0;
      animation.onComplete = () {
        callbackInvoked++;
      };
      final component = SpriteAnimationComponent(animation: animation);
      await game.ensureAdd(component);
      game.update(0.01);
      expect(animation.currentIndex, 0);
      game.update(0.1);
      expect(animation.currentIndex, 1);
      game.update(0.3);
      expect(animation.currentIndex, 4);
      game.update(0.089);
      // At this point we're still on the last frame, which has
      // almost finished. Total clock time = 0.499 s
      expect(animation.currentIndex, 4);
      expect(animation.clock, closeTo(0.099, 1e-10));
      expect(animation.done(), false);
      expect(callbackInvoked, 0);
      // This last tick moves the total clock to 0.5001 s,
      // completing the last animation frame.
      game.update(0.0011);
      expect(callbackInvoked, 1);
      expect(animation.currentIndex, 4);
      expect(animation.done(), true);
      // Now move the timer forward again, and verify that the callback won't be
      // invoked multiple times.
      for (var i = 0; i < 10; i++) {
        game.update(1);
      }
      expect(callbackInvoked, 1);
      expect(animation.currentIndex, 4);
      expect(animation.done(), true);
      // Lastly, let's reset the animation and see if it still works properly
      callbackInvoked = 0;
      animation.reset();
      expect(animation.currentIndex, 0);
      expect(animation.done(), false);
      game.update(100);
      expect(callbackInvoked, 1);
      expect(animation.currentIndex, 4);
      expect(animation.done(), true);
    });
  });

  group('SpriteAnimationComponent.autoResize', () {
    test('mutual exclusive with size while construction', () {
      expect(
        () => SpriteAnimationComponent(autoResize: true, size: Vector2.all(2)),
        throwsAssertionError,
      );

      expect(
        () => SpriteAnimationComponent(autoResize: false),
        throwsAssertionError,
      );
    });

    test('default value set correctly when not provided explicitly', () {
      final component1 = SpriteAnimationComponent();
      final component2 = SpriteAnimationComponent(size: Vector2.all(2));

      expect(component1.autoResize, true);
      expect(component2.autoResize, false);
    });

    test('resizes on animation update', () {
      final spriteList = [
        Sprite(image, srcSize: Vector2.all(1)),
        Sprite(image, srcSize: Vector2.all(2)),
        Sprite(image, srcSize: Vector2.all(3)),
      ];
      final animation = SpriteAnimation.spriteList(
        spriteList,
        stepTime: 1,
        loop: false,
      );

      final component = SpriteAnimationComponent(animation: animation);
      expect(component.size, spriteList[0].srcSize);

      component.update(1);
      expect(component.size, spriteList[1].srcSize);

      component.update(1);
      expect(component.size, spriteList[2].srcSize);
    });

    test('resizes only when true', () {
      final spriteList = [
        Sprite(image, srcSize: Vector2.all(1)),
        Sprite(image, srcSize: Vector2.all(2)),
      ];
      final animation = SpriteAnimation.spriteList(
        spriteList,
        stepTime: 1,
        loop: false,
      );
      final component = SpriteAnimationComponent(animation: animation)
        ..autoResize = false;

      component.update(1);
      expect(component.size, spriteList[0].srcSize);

      component.autoResize = true;
      expect(component.size, spriteList[1].srcSize);
    });

    test('stop autoResizing on external size modifications', () {
      final spriteList = [
        Sprite(image, srcSize: Vector2.all(1)),
        Sprite(image, srcSize: Vector2.all(2)),
      ];
      final animation = SpriteAnimation.spriteList(
        spriteList,
        stepTime: 1,
        loop: false,
      );
      final testSize = Vector2(83, 100);
      final component = SpriteAnimationComponent();

      // NOTE: Sequence of modifications is important here. Changing the size
      // first disables the auto-resizing. So even if animation is changed
      // later, the component should still maintain testSize.
      component
        ..size = testSize
        ..animation = animation;

      expectDouble(component.size.x, testSize.x);
      expectDouble(component.size.y, testSize.y);
    });
  });
}
