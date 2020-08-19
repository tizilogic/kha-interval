package interval;

import kha.FastFloat;
import interval.Types;


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
