import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.FlxCamera;

class CustomFadeTransition extends MusicBeatSubstate {

    public static var finishCallback:Void->Void;
    private var leTween:FlxTween = null;
    public static var nextCamera:FlxCamera;
    var isTransIn:Bool = false;
    var transBlack:FlxSprite;
    var transGradient:FlxSprite;

    public function new(duration:Float, isTransIn:Bool) {
        super();
        this.isTransIn = isTransIn;

        var zoom:Float = CoolUtil.boundTo(FlxG.camera.zoom, 0.05, 1);
        var width:Int = Std.int(FlxG.width / zoom);
        var height:Int = Std.int(FlxG.height / zoom);

        // gradient
        transGradient = FlxGradient.createGradientFlxSprite(width, height, [FlxColor.BLACK, 0x0]);
        transGradient.scrollFactor.set(0, 0);
        transGradient.alpha = isTransIn ? 1 : 0;
        add(transGradient);

        // Nigga bg
        transBlack = new FlxSprite().makeGraphic(width, height, FlxColor.BLACK);
        transBlack.scrollFactor.set(0, 0);
        transBlack.alpha = isTransIn ? 1 : 0;
        add(transBlack);

        // fade in/out anim script
        if (isTransIn) {
            transGradient.alpha = transBlack.alpha = 1;
            FlxTween.tween(transGradient, {alpha: 0}, duration + 0.3, {
                onComplete: function(twn:FlxTween) {
                    close();
                },
                ease: FlxEase.linear
            });
            FlxTween.tween(transBlack, {alpha: 0}, duration + 0.3, {ease: FlxEase.linear});
        } else {
            transGradient.alpha = transBlack.alpha = 0;
            leTween = FlxTween.tween(transGradient, {alpha: 1}, duration, {
                onComplete: function(twn:FlxTween) {
                    if (finishCallback != null) {
                        if (finishCallback != null) {
                            finishCallback();
                        }
                    }
                },
                ease: FlxEase.linear
            });
            FlxTween.tween(transBlack, {alpha: 1}, duration, {ease: FlxEase.linear});
        }

        // connecting to camera
        if (nextCamera != null) {
            transBlack.cameras = [nextCamera];
            transGradient.cameras = [nextCamera];
        }
        nextCamera = null;
    }

    override function destroy() {
        if (leTween != null) {
            finishCallback();
            leTween.cancel();
        }
        super.destroy();
    }
}
