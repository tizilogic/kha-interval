package interval;

import kha.FastFloat;


enum BlendType {
    LINEAR;
    SINE_IN;
    SINE_OUT;
    SINE_IN_OUT;
    QUAD_IN;
    QUAD_OUT;
    QUAD_IN_OUT;
    CUBIC_IN;
    CUBIC_OUT;
    CUBIC_IN_OUT;
    QUART_IN;
    QUART_OUT;
    QUART_IN_OUT;
    QUINT_IN;
    QUINT_OUT;
    QUINT_IN_OUT;
    EXPO_IN;
    EXPO_OUT;
    EXPO_IN_OUT;
    CIRC_IN;
    CIRC_OUT;
    CIRC_IN_OUT;
    BACK_IN;
    BACK_OUT;
    BACK_IN_OUT;
    BOUNCE_IN;
    BOUNCE_OUT;
    BOUNCE_IN_OUT;
    ELASTIC_IN;
    ELASTIC_OUT;
    ELASTIC_IN_OUT;
}


@:enum
abstract Modifier (Int) to Int {
    var SX = 1;
    var EX = 2;
    var SY = 4;
    var EY = 8;
    var SALPHA = 16;
    var EALPHA = 32;
    var SANGLE = 64;
    var EANGLE = 128;
    var SSCALEX = 256;
    var ESCALEX = 512;
    var SSCALEY = 1024;
    var ESCALEY = 2048;
    var RNODE = 4096;
    var FUNC = 8192;
}


enum PlaybackState {
    NOT_STARTED;
    START;
    PLAYING;
    PAUSED;
    FINISHED;
}


interface Playable {
    public var inSequence:Bool;
    private var _loop:Bool;
    private var _keepAlive:Bool;

    public function play():Void;
    public function pause():Void;
    public function resume():Void;
    public function stop():Void;
    public function step(dt:FastFloat):FastFloat;
    public function remove(?_auto:Bool = false):Void;
    public function loop(?_set:Bool = true):Void;
}
