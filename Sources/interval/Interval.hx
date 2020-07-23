package interval;

import kha.FastFloat;

import interval.Types;
import scenegraph.Node;


/**
 * Intervals are intended to be one-shot instances to start and forget, using the provided
 * factory functions to create, though more control is provided if needed, `new` is marked private
 * to control instantiation. At runtime, finished, non looping Interval instances will be retained
 * in memory to prevent GC and reused to skip allocation.
 */
@:allow(interval.Sequence)
class Interval implements Playable {
    private static var node = new Array<Node>();
    private static var duration = new Array<FastFloat>();
    private static var cursor = new Array<FastFloat>();
    private static var activeModifiers = new Array<Int>();
    private static var sX = new Array<FastFloat>();  // 1
    private static var eX = new Array<FastFloat>();  // 2
    private static var sY = new Array<FastFloat>();  // 4
    private static var eY = new Array<FastFloat>();  // 8
    private static var sAlpha = new Array<FastFloat>();  // 16
    private static var eAlpha = new Array<FastFloat>();  // 32
    private static var sAngle = new Array<FastFloat>();  // 64
    private static var eAngle = new Array<FastFloat>();  // 128
    private static var sScaleX = new Array<FastFloat>();  // 256
    private static var eScaleX = new Array<FastFloat>();  // 512
    private static var sScaleY = new Array<FastFloat>();  // 1024
    private static var eScaleY = new Array<FastFloat>();  // 2048
    private static var rNode = new Array<Node>();  // 4096
    private static var func = new Array<FastFloat -> Void>();  // 4096
    private static var blendType:Array<BlendType> = new Array<BlendType>();
    private static var callback:Array<Void -> Void> = new Array<Void -> Void>();
    private static var _free = new Array<Int>();
    private static var _freeIntervals = new Array<Interval>();

    private static function newId(dur:FastFloat, node:Node, ?blend:BlendType = LINEAR, ?rel:Node = null):Int {
        var id:Int;
        if (_free.length > 0) {
            id = _free.pop();
            Interval.node[id] = node;
            duration[id] = dur;
            cursor[id] = -1;
            rNode[id] = rel;
            blendType[id] = blend;
            callback[id] = null;
        }
        else {
            id = Interval.node.length;
            Interval.node.push(node);
            duration.push(dur);
            cursor.push(-1);
            activeModifiers.push(0);
            sX.push(0);
            eX.push(0);
            sY.push(0);
            eY.push(0);
            sAlpha.push(0);
            eAlpha.push(0);
            sAngle.push(0);
            eAngle.push(0);
            sScaleX.push(0);
            eScaleX.push(0);
            sScaleY.push(0);
            eScaleY.push(0);
            rNode.push(rel);
            blendType.push(blend);
            callback.push(null);
        }
        activeModifiers[id] = rNode[id] != null ? RNODE : 0;
        return id;
    }

    private static function removeId(id:Int) {
        _free.push(id);
    }

    private static function getInterval(duration:FastFloat, node:Node, ?blend:BlendType = LINEAR, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        if (_freeIntervals.length > 0) {
            var ival =  _freeIntervals.pop();
            ival._loop = false;
            ival._keepAlive = keepAlive;
            ival._state = NOT_STARTED;
            Interval.duration[ival.id] = duration;
            Interval.blendType[ival.id] = blend;
            Interval.callback[ival.id] = null;
            Interval.activeModifiers[ival.id] = 0;
            Interval.cursor[ival.id] = -1;
            ival.setRelativeNode(rel);
            return ival;
        }
        return new Interval(duration, node, blend, rel, keepAlive);
    }

    // Interval factory functions
    public static function x(duration:FastFloat, node:Node, eX:FastFloat, ?sX:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, node, blend, rel, keepAlive);
        ival.xMod(eX, sX);
        Interval.callback[ival.id] = callback;
        return ival;
    }

    public static function y(duration:FastFloat, node:Node, eY:FastFloat, ?sY:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, node, blend, rel, keepAlive);
        ival.yMod(eY, sY);
        Interval.callback[ival.id] = callback;
        return ival;
    }

    public static function pos(duration:FastFloat, node:Node, eX:FastFloat, ?sX:Null<FastFloat>, eY:FastFloat, ?sY:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, node, blend, rel, keepAlive);
        ival.xMod(eX, sX);
        ival.yMod(eY, sY);
        Interval.callback[ival.id] = callback;
        return ival;
    }

    public static function alpha(duration:FastFloat, node:Node, eAlpha:FastFloat, ?sAlpha:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, node, blend, rel, keepAlive);
        ival.alphaMod(eAlpha, sAlpha);
        Interval.callback[ival.id] = callback;
        return ival;
    }

    public static function angle(duration:FastFloat, node:Node, eAngle:FastFloat, ?sAngle:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, node, blend, rel, keepAlive);
        ival.angleMod(eAngle, sAngle);
        Interval.callback[ival.id] = callback;
        return ival;
    }

    public static function scaleX(duration:FastFloat, node:Node, eScale:FastFloat, sScale:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, node, blend, rel, keepAlive);
        ival.scaleXMod(eScale, sScale);
        Interval.callback[ival.id] = callback;
        return ival;
    }

    public static function scaleY(duration:FastFloat, node:Node, eScale:FastFloat, sScale:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, node, blend, rel, keepAlive);
        ival.scaleYMod(eScale, sScale);
        Interval.callback[ival.id] = callback;
        return ival;
    }

    public static function scale(duration:FastFloat, node:Node, eScale:FastFloat, sScale:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, node, blend, rel, keepAlive);
        ival.scaleXMod(eScale, sScale);
        ival.scaleYMod(eScale, sScale);
        Interval.callback[ival.id] = callback;
        return ival;
    }

    public static function lerp(duration:FastFloat, func:FastFloat -> Void, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, null, blend, keepAlive);
        ival.setLerpMod(func);
        return ival;
    }

    // Combined interval factory functions
    public static function posAlpha(duration:FastFloat, node:Node, eX:FastFloat, ?sX:Null<FastFloat>, eY:FastFloat, ?sY:Null<FastFloat>, eAlpha:FastFloat, ?sAlpha:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = pos(duration, node, eX, sX, eY, sY, blend, callback, rel, keepAlive);
        ival.alphaMod(eAlpha, sAlpha);
        return ival;
    }

    public static function posAngle(duration:FastFloat, node:Node, eX:FastFloat, ?sX:Null<FastFloat>, eY:FastFloat, ?sY:Null<FastFloat>, eAngle:FastFloat, ?sAngle:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = pos(duration, node, eX, sX, eY, sY, blend, callback, rel, keepAlive);
        ival.angleMod(eAngle, sAngle);
        return ival;
    }

    public static function angleAlpha(duration:FastFloat, node:Node, eAngle:FastFloat, ?sAngle:Null<FastFloat>, eAlpha:FastFloat, ?sAlpha:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = angle(duration, node, eAngle, sAngle, blend, callback, rel, keepAlive);
        ival.alphaMod(eAlpha, sAlpha);
        return ival;
    }

    // Instance
    public var id:Int;
    public var inSequence:Bool;

    private var _loop:Bool;
    private var _first:Bool = true;
    private var _state:PlaybackState = NOT_STARTED;
    private var _keepAlive:Bool;

    private function new(duration:FastFloat, node:Node, ?blend:BlendType = LINEAR, ?rel:Node = null, ?keepAlive:Bool = false) {
        id = newId(duration, node, blend, rel);
        _keepAlive = keepAlive;
        _loop = false;
        inSequence = false;
    }

    public inline function xMod(eX:FastFloat, ?sX:Null<FastFloat>) {
        Interval.eX[id] = eX;
        activeModifiers[id] |= EX;
        if (sX != null) {
            Interval.sX[id] = sX;
            activeModifiers[id] |= SX;
        }
    }

    public inline function yMod(eY:FastFloat, ?sY:Null<FastFloat>) {
        Interval.eY[id] = eY;
        activeModifiers[id] |= EY;
        if (sY != null) {
            Interval.sY[id] = sY;
            activeModifiers[id] |= SY;
        }
    }

    public inline function alphaMod(eAlpha:FastFloat, ?sAlpha:Null<FastFloat>) {
        Interval.eAlpha[id] = eAlpha;
        activeModifiers[id] |= EALPHA;
        if (sAlpha != null) {
            Interval.sAlpha[id] = sAlpha;
            activeModifiers[id] |= SALPHA;
        }
    }

    public inline function angleMod(eAngle:FastFloat, ?sAngle:Null<FastFloat>) {
        Interval.eAngle[id] = eAngle;
        activeModifiers[id] |= EANGLE;
        if (sAngle != null) {
            Interval.sAngle[id] = sAngle;
            activeModifiers[id] |= SANGLE;
        }
    }

    public inline function scaleXMod(eScaleX:FastFloat, ?sScaleX:Null<FastFloat>) {
        Interval.eScaleX[id] = eScaleX;
        activeModifiers[id] |= ESCALEX;
        if (sScaleX != null) {
            Interval.sScaleX[id] = sScaleX;
            activeModifiers[id] |= SSCALEX;
        }
    }

    public inline function scaleYMod(eScaleY:FastFloat, ?sScaleY:Null<FastFloat>) {
        Interval.eScaleY[id] = eScaleY;
        activeModifiers[id] |= ESCALEY;
        if (sScaleY != null) {
            Interval.sScaleY[id] = sScaleY;
            activeModifiers[id] |= SSCALEY;
        }
    }

    public inline function setRelativeNode(?rel:Node = null) {
        if (rel != null) {
            rNode[id] = rel;
            activeModifiers[id] |= RNODE;
        }
        else if (activeModifiers[id] & RNODE > 0) {
            activeModifiers[id] ^= RNODE;
        }
    }

    public inline function setLerpMod(f:FastFloat -> Void) {
        activeModifiers[id] |= FUNC;
        func[id] = f;
    }

    public inline function play():Void {
        if (_state != NOT_STARTED && _state != FINISHED && _state != PAUSED) {
            throw "Invalid state to call play";
        }
        cursor[id] = 0;
        if (_state != PAUSED) {
            if (!inSequence) {
                IntervalManager._playQueue.push(this);
            }
            _state = START;
        }
        else {
            _state = PLAYING;
        }
    }

    public inline function pause():Void {
        _state = PAUSED;
    }

    public inline function resume():Void {
        if (_state != PAUSED) {
            throw "Can only resume paused Intervals";
        }
        _state = PLAYING;
    }

    public inline function stop():Void {
        _state = FINISHED;
    }

    public inline function step(dt:FastFloat):FastFloat {
        switch (_state) {
            case START: reset();
            case PAUSED | NOT_STARTED: return -1;
            case FINISHED:
                if (callback[id] != null) {
                    callback[id]();
                }
                remove(true);
                return dt;
            case PLAYING:
                if (IntervalManager._activeNodes.exists(node[id].id) && IntervalManager._activeNodes[node[id].id] & activeModifiers[id] > 0) {
                    _state = FINISHED;
                    if (callback[id] != null) {
                        callback[id]();
                    }
                    remove(true);
                    return -2;
                }
            default:
        }
        cursor[id] += dt;
        var rdt = cursor[id] < duration[id] ? -1 : cursor[id] - duration[id];
        var k = Lerp.ease(cursor[id], duration[id], blendType[id]);
        if (activeModifiers[id] & RNODE > 0) {
            if (activeModifiers[id] & EX > 0 && activeModifiers[id] & EY > 0) {
                node[id].setRelativePos(rNode[id], (eX[id] - sX[id]) * k + sX[id], (eY[id] - sY[id]) * k + sY[id]);
            }
            else if (activeModifiers[id] & EX > 0) {
                node[id].setRelativePos(rNode[id], (eX[id] - sX[id]) * k + sX[id], node[id].getRelativePos(rNode[id]).y);
            }
            else if (activeModifiers[id] & EY > 0) {
                node[id].setRelativePos(rNode[id], node[id].getRelativePos(rNode[id]).x, (eY[id] - sY[id]) * k + sY[id]);
            }
            if (activeModifiers[id] & EANGLE > 0) {
                node[id].setRelativeAngle(rNode[id], (eAngle[id] - sAngle[id]) * k + sAngle[id]);
            }
            if (activeModifiers[id] & ESCALEX > 0) {
                node[id].setRelativeScaleX(rNode[id], (eScaleX[id] - sScaleX[id]) * k + sScaleX[id]);
            }
            if (activeModifiers[id] & ESCALEY > 0) {
                node[id].setRelativeScaleY(rNode[id], (eScaleY[id] - sScaleY[id]) * k + sScaleY[id]);
            }
        }
        else {
            if (activeModifiers[id] & EX > 0) {
                node[id].x = (eX[id] - sX[id]) * k + sX[id];
            }
            if (activeModifiers[id] & EY > 0) {
                node[id].y = (eY[id] - sY[id]) * k + sY[id];
            }
            if (activeModifiers[id] & EANGLE > 0) {
                node[id].angle = (eAngle[id] - sAngle[id]) * k + sAngle[id];
            }
            if (activeModifiers[id] & ESCALEX > 0) {
                node[id].scaleX = (eScaleX[id] - sScaleX[id]) * k + sScaleX[id];
            }
            if (activeModifiers[id] & ESCALEY > 0) {
                node[id].scaleY = (eScaleY[id] - sScaleY[id]) * k + sScaleY[id];
            }
        }
        if (activeModifiers[id] & EALPHA > 0) {
            node[id].alpha = (eAlpha[id] - sAlpha[id]) * k + sAlpha[id];
        }
        if (activeModifiers[id] & FUNC > 0) {
            func[id](k);
        }
        if (rdt != -1) {
            if (callback[id] != null) {
                callback[id]();
            }
            _state = FINISHED;
            if (_loop) {
                play();
                return step(rdt);
            }
            else {
                remove(true);
            }
        }
        if (IntervalManager._activeNodes.exists(node[id].id)) {
            IntervalManager._activeNodes[node[id].id] = activeModifiers[id] | IntervalManager._activeNodes[node[id].id];
        }
        else {
            IntervalManager._activeNodes[node[id].id] = activeModifiers[id];
        }
        return rdt;
    }

    private inline function reset() {
        if (_first) {
            if (activeModifiers[id] & RNODE > 0) {
                if (activeModifiers[id] & EX > 0 && activeModifiers[id] & SX == 0) {
                    sX[id] = node[id].getRelativePos(rNode[id]).x;
                }
                if (activeModifiers[id] & EY > 0 && activeModifiers[id] & SY == 0) {
                    sX[id] = node[id].getRelativePos(rNode[id]).y;
                }
                if (activeModifiers[id] & EANGLE > 0 && activeModifiers[id] & SANGLE == 0) {
                    sAngle[id] = node[id].getRelativeAngle(rNode[id]);
                }
                if (activeModifiers[id] & ESCALEX > 0 && activeModifiers[id] & SSCALEX == 0) {
                    sScaleX[id] = node[id].getRelativeScaleX(rNode[id]);
                }
                if (activeModifiers[id] & ESCALEY > 0 && activeModifiers[id] & SSCALEY == 0) {
                    sScaleY[id] = node[id].getRelativeScaleY(rNode[id]);
                }
            }
            else {
                if (activeModifiers[id] & EX > 0 && activeModifiers[id] & SX == 0) {
                    sX[id] = node[id].x;
                }
                if (activeModifiers[id] & EY > 0 && activeModifiers[id] & SY == 0) {
                    sY[id] = node[id].y;
                }
                if (activeModifiers[id] & EANGLE > 0 && activeModifiers[id] & SANGLE == 0) {
                    sAngle[id] = node[id].angle;
                }
                if (activeModifiers[id] & ESCALEX > 0 && activeModifiers[id] & SSCALEX == 0) {
                    sScaleX[id] = node[id].scaleX;
                }
                if (activeModifiers[id] & ESCALEY > 0 && activeModifiers[id] & SSCALEY == 0) {
                    sScaleY[id] = node[id].scaleY;
                }
            }
            if (activeModifiers[id] & EALPHA > 0 && activeModifiers[id] & SALPHA == 0) {
                sAlpha[id] = node[id].alpha;
            }
        }
        _state = PLAYING;
        _first = false;
    }

    public inline function remove(?_auto:Bool = false):Void {
        if (!inSequence) {
            IntervalManager._removeQueue.push(this);
        }
        if (!_keepAlive || !_auto) {
            removeId(id);
        }
    }

    public inline function loop(?_set:Bool = true) {
        _loop = _set;
    }
}


class Sequence implements Playable {
    public var inSequence:Bool;
    private var _loop:Bool;
    private var _interval:Array<Playable>;
    private var _cursor:Int = -1;
    private var _callback:Void -> Void;
    private var _state:PlaybackState = NOT_STARTED;
    private var _keepAlive:Bool;

    public function new(?intervals:Array<Playable> = null) {
        inSequence = false;
        if (intervals != null) {
            _interval = intervals;
        }
        else {
            _interval = new Array<Playable>();
        }
        for (i in _interval) {
            i.inSequence = true;
            i._loop = false;
            i._keepAlive = true;
        }
    }

    public inline function append(ival:Playable) {
        ival.inSequence = true;
        _interval.push(ival);
    }

    public inline function play():Void {
        if (_interval.length == 0) {
            throw "Empty sequence";
        }
        else if (_state != NOT_STARTED && _state != FINISHED && _state != PAUSED) {
            throw "Invalid state to call play";
        }

        IntervalManager._playQueue.push(this);
        _cursor = 0;
        _interval[0].play();
        _state = PLAYING;
    }

    public inline function pause():Void {
        _state = PAUSED;
    }

    public inline function resume():Void {
        if (_state != PAUSED) {
            throw "Can only resume paused Sequence";
        }
        _state = PLAYING;
    }

    public inline function stop():Void {
        if (_cursor != -1) {
            _interval[_cursor].stop();
        }
    }

    public inline function step(dt:FastFloat):FastFloat {
        var rdt = dt;
        while (rdt >= 0) {
            switch (_state) {
                case PAUSED | NOT_STARTED: return -1;
                case FINISHED:
                    if (_callback != null) {
                        _callback();
                    }
                    remove(true);
                    return dt;
                case PLAYING:
                    rdt = _interval[_cursor].step(rdt);
                    if (rdt == -1) {
                        break;
                    }
                    else if (rdt == -2) {
                        remove(true);
                        break;
                    }
                    else {
                        ++_cursor;
                        if (_cursor == _interval.length) {
                            if (_loop) {
                                _cursor = 0;
                            }
                            else {
                                remove(true);
                                break;
                            }
                        }
                        _interval[_cursor].play();
                    }
                default:
            }
        }
        return rdt;
    }

    public inline function remove(?_auto:Bool = false):Void {
        if (!inSequence) {
            IntervalManager._removeQueue.push(this);
        }
    }

    public inline function loop(?_set:Bool = true) {
        _loop = _set;
    }
}


@:allow(interval.Playable)
class IntervalManager {
    private static var _activeNodes = new Map<Int,Int>();
    private static var _playQueue = new Array<Playable>();
    private static var _removeQueue = new Array<Playable>();

    public static function step(dt:FastFloat) {
        _activeNodes.clear();
        for (i in _playQueue) {
            i.step(dt);
        }
        while (_removeQueue.length > 0) {
            _playQueue.remove(_removeQueue.pop());
        }
    }
}


class Lerp {
    // Adapted from Iron's tween (https://github.com/armory3d/iron/blob/master/Sources/iron/system/Tween.hx)
    private static inline var DEFAULT_OVERSHOOT: FastFloat = 1.70158;

    public static function ease(cursor:FastFloat, duration:FastFloat, ?blendType:BlendType = LINEAR):FastFloat {
        var k = cursor / duration;
        switch (blendType) {
            case SINE_IN: return easeSineIn(k);
            case SINE_OUT: return easeSineOut(k);
            case SINE_IN_OUT: return easeSineInOut(k);
            case QUAD_IN: return easeQuadIn(k);
            case QUAD_OUT: return easeQuadOut(k);
            case QUAD_IN_OUT: return easeQuadInOut(k);
            case CUBIC_IN: return easeCubicIn(k);
            case CUBIC_OUT: return easeCubicOut(k);
            case CUBIC_IN_OUT: return easeCubicInOut(k);
            case QUART_IN: return easeQuartIn(k);
            case QUART_OUT: return easeQuartOut(k);
            case QUART_IN_OUT: return easeQuartInOut(k);
            case QUINT_IN: return easeQuintIn(k);
            case QUINT_OUT: return easeQuintOut(k);
            case QUINT_IN_OUT: return easeQuintInOut(k);
            case EXPO_IN: return easeExpoIn(k);
            case EXPO_OUT: return easeExpoOut(k);
            case EXPO_IN_OUT: return easeExpoInOut(k);
            case CIRC_IN: return easeCircIn(k);
            case CIRC_OUT: return easeCircOut(k);
            case CIRC_IN_OUT: return easeCircInOut(k);
            case BACK_IN: return easeBackIn(k);
            case BACK_OUT: return easeBackOut(k);
            case BACK_IN_OUT: return easeBackInOut(k);
            case BOUNCE_IN: return easeBounceIn(k);
            case BOUNCE_OUT: return easeBounceOut(k);
            case BOUNCE_IN_OUT: return easeBounceInOut(k);
            case ELASTIC_IN: return easeElasticIn(k);
            case ELASTIC_OUT: return easeElasticOut(k);
            case ELASTIC_IN_OUT: return easeElasticInOut(k);
            default: return k;
        }
    }

    public static function easeSineIn(k:FastFloat):FastFloat { if (k == 0) { return 0; } else if (k == 1) { return 1; } else { return 1 - Math.cos(k * Math.PI / 2); } }
	public static function easeSineOut(k:FastFloat):FastFloat { if (k == 0) { return 0; } else if (k == 1) { return 1; } else { return Math.sin(k * (Math.PI * 0.5)); } }
	public static function easeSineInOut(k:FastFloat):FastFloat { if (k == 0) { return 0; } else if (k == 1) { return 1; } else { return -0.5 * (Math.cos(Math.PI * k) - 1); } }
	public static function easeQuadIn(k:FastFloat):FastFloat { return k * k; }
	public static function easeQuadOut(k:FastFloat):FastFloat { return -k * (k - 2); }
	public static function easeQuadInOut(k:FastFloat):FastFloat { return (k < 0.5) ? 2 * k * k : -2 * ((k -= 1) * k) + 1; }
	public static function easeCubicIn(k:FastFloat):FastFloat { return k * k * k; }
	public static function easeCubicOut(k:FastFloat):FastFloat { return (k = k - 1) * k * k + 1; }
	public static function easeCubicInOut(k:FastFloat):FastFloat { return ((k *= 2) < 1) ? 0.5 * k * k * k : 0.5 * ((k -= 2) * k * k + 2); }
	public static function easeQuartIn(k:FastFloat):FastFloat { return (k *= k) * k; }
	public static function easeQuartOut(k:FastFloat):FastFloat { return 1 - (k = (k = k - 1) * k) * k; }
	public static function easeQuartInOut(k:FastFloat):FastFloat { return ((k *= 2) < 1) ? 0.5 * (k *= k) * k : -0.5 * ((k = (k -= 2) * k) * k - 2); }
	public static function easeQuintIn(k:FastFloat):FastFloat { return k * (k *= k) * k; }
	public static function easeQuintOut(k:FastFloat):FastFloat { return (k = k - 1) * (k *= k) * k + 1; }
	public static function easeQuintInOut(k:FastFloat):FastFloat { return ((k *= 2) < 1) ? 0.5 * k * (k *= k) * k : 0.5 * (k -= 2) * (k *= k) * k + 1; }
	public static function easeExpoIn(k:FastFloat):FastFloat { return k == 0 ? 0 : Math.pow(2, 10 * (k - 1)); }
	public static function easeExpoOut(k:FastFloat):FastFloat { return k == 1 ? 1 : (1 - Math.pow(2, -10 * k)); }
	public static function easeExpoInOut(k:FastFloat):FastFloat { if (k == 0) { return 0; } if (k == 1) { return 1; } if ((k /= 1 / 2.0) < 1.0) { return 0.5 * Math.pow(2, 10 * (k - 1)); } return 0.5 * (2 - Math.pow(2, -10 * --k)); }
	public static function easeCircIn(k:FastFloat):FastFloat { return -(Math.sqrt(1 - k * k) - 1); }
	public static function easeCircOut(k:FastFloat):FastFloat { return Math.sqrt(1 - (k - 1) * (k - 1)); }
	public static function easeCircInOut(k:FastFloat):FastFloat { return k <= .5 ? (Math.sqrt(1 - k * k * 4) - 1) / -2 : (Math.sqrt(1 - (k * 2 - 2) * (k * 2 - 2)) + 1) / 2; }
	public static function easeBackIn(k:FastFloat):FastFloat { if (k == 0) { return 0; } else if (k == 1) { return 1; } else { return k * k * ((DEFAULT_OVERSHOOT + 1) * k - DEFAULT_OVERSHOOT); } }
	public static function easeBackOut(k:FastFloat):FastFloat { if (k == 0) { return 0; } else if (k == 1) { return 1; } else { return ((k = k - 1) * k * ((DEFAULT_OVERSHOOT + 1) * k + DEFAULT_OVERSHOOT) + 1); } }
	public static function easeBackInOut(k:FastFloat):FastFloat { if (k == 0) { return 0; } else if (k == 1) { return 1; } else if ((k *= 2) < 1) { return (0.5 * (k * k * (((DEFAULT_OVERSHOOT * 1.525) + 1) * k - DEFAULT_OVERSHOOT * 1.525))); } else { return (0.5 * ((k -= 2) * k * (((DEFAULT_OVERSHOOT * 1.525) + 1) * k + DEFAULT_OVERSHOOT * 1.525) + 2)); } }
	public static function easeBounceIn(k:FastFloat):FastFloat { return 1 - easeBounceOut(1 - k); }
	public static function easeBounceOut(k:FastFloat):FastFloat { return if (k < (1 / 2.75)) { 7.5625 * k * k; } else if (k < (2 / 2.75)) { 7.5625 * (k -= (1.5 / 2.75)) * k + 0.75; } else if (k < (2.5 / 2.75)) { 7.5625 * (k -= (2.25 / 2.75)) * k + 0.9375; } else { 7.5625 * (k -= (2.625 / 2.75)) * k + 0.984375; } }
	public static function easeBounceInOut(k:FastFloat):FastFloat { return (k < 0.5) ? easeBounceIn(k * 2) * 0.5 : easeBounceOut(k * 2 - 1) * 0.5 + 0.5; }

	public static function easeElasticIn(k:FastFloat):FastFloat {
		var s: Null<FastFloat> = null;
		var a = 0.1, p = 0.4;
		if (k == 0) {
			return 0;
		}
		if (k == 1) {
			return 1;
		}
		if (a < 1) {
			a = 1;
			s = p / 4;
		}
		else {
			s = p * Math.asin(1 / a) / (2 * Math.PI);
		}
		return -(a * Math.pow(2, 10 * (k -= 1)) * Math.sin((k - s) * (2 * Math.PI) / p));
	}

	public static function easeElasticOut(k:FastFloat):FastFloat {
		var s: Null<FastFloat> = null;
		var a = 0.1, p = 0.4;
		if (k == 0) {
			return 0;
		}
		if (k == 1) {
			return 1;
		}
		if (a < 1) {
			a = 1;
			s = p / 4;
		}
		else {
			s = p * Math.asin(1 / a) / (2 * Math.PI);
		}
		return (a * Math.pow(2, -10 * k) * Math.sin((k - s) * (2 * Math.PI) / p) + 1);
	}

	public static function easeElasticInOut(k:FastFloat):FastFloat {
		var s, a = 0.1, p = 0.4;
		if (k == 0) {
			return 0;
		}
		if (k == 1) {
			return 1;
		}
		if (a != 0 || a < 1) {
			a = 1;
			s = p / 4;
		}
		else {
			s = p * Math.asin(1 / a) / (2 * Math.PI);
		}
		if ((k *= 2) < 1) return - 0.5 * (a * Math.pow(2, 10 * (k -= 1)) * Math.sin((k - s) * (2 * Math.PI) / p));
		return a * Math.pow(2, -10 * (k -= 1)) * Math.sin((k - s) * (2 * Math.PI) / p) * 0.5 + 1;
    }
}
