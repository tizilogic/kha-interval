package interval;

import kha.FastFloat;

import interval.Types;
import interval.IntervalManager;
import interval.Lerp;
import scenegraph.Node;


/**
 * Intervals are intended to be one-shot instances to start and forget, using the provided
 * factory functions to create, though more control is provided if needed, `new` is marked private
 * to control instantiation. At runtime, finished, non looping Interval instances will be retained
 * in memory to prevent GC and reused to skip allocation.
 */
@:allow(interval.Parallel, interval.Sequence)
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
    private static var beforeCallback:Array<Void -> Void> = new Array<Void -> Void>();
    private static var _freeIntervals = new Array<Interval>();

    private static function newId(dur:FastFloat, node:Node, ?blend:BlendType = LINEAR, ?rel:Node = null):Int {
        var id:Int = Interval.node.length;
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
        beforeCallback.push(null);
        activeModifiers[id] = rNode[id] != null ? RNODE : 0;
        return id;
    }

    private static function getInterval(duration:FastFloat, node:Node, ?blend:BlendType = LINEAR, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        if (_freeIntervals.length > 0) {
            var ival = _freeIntervals.shift();
            ival._first = true;
            ival.inSequence = false;
            ival._invalid = false;
            ival._loop = false;
            ival._keepAlive = keepAlive;
            ival._state = NOT_STARTED;
            Interval.duration[ival.id] = duration;
            Interval.blendType[ival.id] = blend;
            Interval.callback[ival.id] = null;
            Interval.beforeCallback[ival.id] = null;
            Interval.activeModifiers[ival.id] = 0;
            Interval.cursor[ival.id] = -1;
            Interval.node[ival.id] = node;
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

    public static function pos(duration:FastFloat, node:Node, posMod:PosMod, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, node, blend, rel, keepAlive);
        ival.xMod(posMod.eX, posMod.sX);
        ival.yMod(posMod.eY, posMod.sY);
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

    public static function nop(duration:FastFloat, ?callback:Void -> Void = null, ?keepAlive:Bool = false):Interval {
        var ival = getInterval(duration, null, LINEAR, keepAlive);
        ival.setPauseMod();
        return ival;
    }

    // Combined interval factory functions
    public static function posAlpha(duration:FastFloat, node:Node, posMod:PosMod, eAlpha:FastFloat, ?sAlpha:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = pos(duration, node, posMod, blend, callback, rel, keepAlive);
        ival.alphaMod(eAlpha, sAlpha);
        return ival;
    }

    public static function posAngle(duration:FastFloat, node:Node, posMod:PosMod, eAngle:FastFloat, ?sAngle:Null<FastFloat>, ?blend:BlendType = LINEAR, ?callback:Void -> Void = null, ?rel:Node = null, ?keepAlive:Bool = false):Interval {
        var ival = pos(duration, node, posMod, blend, callback, rel, keepAlive);
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
    private var _invalid = false;

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

    public inline function setPauseMod() {
        activeModifiers[id] |= PAUSE;
    }

    public inline function setCallback(cb:Void -> Void) {
        Interval.callback[id] = cb;
    }

    public inline function setBeforeCallback(cb:Void -> Void) {
        Interval.beforeCallback[id] = cb;
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
                remove(true);
                return dt;
            case PLAYING:
                if (node[id] != null && IntervalManager._activeNodes.exists(node[id].id) && (IntervalManager._activeNodes[node[id].id] & activeModifiers[id]) > 0) {
                    trace("Interval node conflict occurred with: " + node[id] + " @ " + cursor[id] + "s" + " Interval " + id + " ActiveModNode " + IntervalManager._activeNodes[node[id].id] + "ActiveModIVAL " + activeModifiers[id]);
                    // _state = FINISHED;
                    // remove(true);
                    // return -2;
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
            _state = FINISHED;
            if (_loop) {
                if (callback[id] != null) {
                    callback[id]();
                }
                play();
                return step(rdt);
            }
            else {
                remove(true);
            }
        }
        if (node[id] != null && rdt < 0 && activeModifiers[id] != PAUSE) {
            if (IntervalManager._activeNodes.exists(node[id].id)) {
                IntervalManager._activeNodes[node[id].id] = activeModifiers[id] | IntervalManager._activeNodes[node[id].id];
            }
            else {
                IntervalManager._activeNodes[node[id].id] = activeModifiers[id];
            }
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
        if (beforeCallback[id] != null) {
            beforeCallback[id]();
        }
    }

    public inline function remove(?_auto:Bool = false):Void {
        if (_invalid) {
            trace("Attempted to remove invalid Interval: " + this);
            return;
        }
        if (_auto && inSequence) {
            return;
        }
        if (callback[id] != null) {
            callback[id]();
        }
        if (!inSequence) {
            IntervalManager._removeQueue.push(this);
        }
        if (!_keepAlive || !_auto) {
            if (!_invalid) {
                _freeIntervals.push(this);
            }
        }
        _invalid = true;
    }

    public inline function loop(?_set:Bool = true) {
        _loop = _set;
    }

    public inline function length():FastFloat {
        return duration[id];
    }

    public function toString():String {
        var s = "Interval " + id + ": ";
        if (node[id] != null) {
            s = s + "Node '" + node[id] + "' ";
        }
        else {
            if (activeModifiers[id] & FUNC > 0) {
                return "FUNC Interval " + id;
            }
            return s + "<NOP>";
        }
        s = s + " <";
        final modMap = [EX => "X", EY => "Y", EALPHA => "Alpha", ESCALEX => "ScaleX", ESCALEY => "ScaleY", EANGLE => "Angle"];
        var first = true;
        for (i in modMap.keys()) {
            if (activeModifiers[id] & i > 0) {
                if (!first) {
                    s = s + " ";
                }
                s = s + modMap[i];
                first = false;
            }
        }
        return s + ">";
    }
}
