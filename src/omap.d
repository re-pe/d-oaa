/**
 * OMap
 *
 * A fork of Ordered Associative Array, slightly modified by Rėdas Peškaitis.
 * Additions:
 * 1) tuple based OMap constructor 
 * 2) method to export array of [key : value] tuples
 *
 * Repository: https://github.com/re-pe/d-omap
 *  
 * Original Ordered Associative Array by Cédric Picard
 * Email: cedric.picard@efrei.net
 * Repository: https://github.com/cym13/miscD
 *
 * Ordered Associative Array modeled from Python's OrderedDict.
 *
 * Subtypes built-in associative arrays.
 *
 * It works by using an array to keep the key order in addition to a regular
 * associative array.
 */
import std.traits;
 
struct OMap(T) if (isAssociativeArray!T) {
    import std.algorithm;
    import std.typecons;

    alias KeyType!T   keyT;
    alias ValueType!T valueT;

    private keyT[] _order;
    private T      _map;

    alias _map this;

    /**
     * Associative Array based Constructor
     */
    this(T base) {
        _order.reserve(base.length);

        foreach (key, value ; base) {
            _order   ~= key;
            _map[key] = value;
        }
    }

    ///
    unittest {
        auto as_arr  = ["one": 1, "two": 2];
        auto omap = OMap(as_arr);
        assert(omap == as_arr);
    }

    /**
     * Ordered Associative Array based Constructor
     */
    this(OMap!T base) {
        _order.reserve(base.length);

        foreach (key, value ; base.byKeyValue) {
            _order   ~= key;
            _map[key] = value;
        }
    }

    ///
    unittest {
        auto omap_1 = OMap(["one": 1, "two": 2, "three": 3]);
        auto omap_2 = OMap(omap_1);
        assert(omap_1 == omap_2);
    }

    /**
     * Array of Tuples based Constructor
     */
    this(Tuple!(keyT, valueT)[] base) {
        _order.reserve(base.length);

        foreach (value ; base) {
            _order   ~= value[0];
            _map[value[0]] = value[1];
        }
    }

    ///
    unittest {
        auto omap1 = OMap([tuple("one", 1), tuple("two", 2), tuple("three", 3)]);
        auto omap2 = OMap(["one": 1, "two": 2, "three": 3]);
        assert(omap1 == omap2);
    }

    /**
     * Remove all contents from the container.
     */
    void clear() {
        _map   = null;
        _order = null;
    }

    ///
    unittest {
        auto omap = OMap(["one": 1, "two": 2]);
        omap.clear;
        assert(omap[].length == 0);
    }

    /**
     * Returns a range of keys in order
     */
    auto byKey() {
        return _order.dup;
    }

    /**
     * Returns a range of values in order
     */
    auto byValue() {
        return _order.map!(x => _map[x]);
    }

    /**
     * Returns a range of tuples (key, value) in order
     */
    auto byKeyValue() {
        return _order.map!(x => tuple(x, _map[x]));
    }

    /**
     * Returns an array of tuples (key, value) in order
     */
    auto tupleArray() {
        import std.array;
        return array(this.byKeyValue);
    }

    unittest {
        auto tup_arr1 = [tuple("one", 1), tuple("two", 2), tuple("three", 3)];
        auto omap1 = OMap(tup_arr1);
        auto tup_arr2 = omap1.tupleArray;
        assert(tup_arr1 == tup_arr2);
    }
    
    auto ref opIndex() {
        return _order[];
    }

    auto ref opIndex(const keyT key) {
        return _map[key];
    }

    void opIndexAssign(const valueT value, const keyT key) {
        if (key !in _map)
            _order ~= key;
        _map[key] = value;
    }

    /**
     * Remove an element in place given its key
     * Returns false if the element wasn't in the array, true otherwise
     */
    bool remove(const keyT key) {
        auto index = _order.countUntil(key);

        if (index == -1)
            return false;

        _order = std.algorithm.remove(_order, index);
        _map.remove(key);
        return true;
    }

    ///
    unittest {
        import std.array:     array;
        import std.algorithm: sort;

        auto omap = OMap(["one": 1, "two": 2, "three": 3]);

        sort(omap[]);
        assert(omap[].array == ["one", "three", "two"]);

        assert(!omap.remove("four"));
        assert(omap[].array == ["one", "three", "two"]);

        assert(omap.remove("three"));
        assert(omap[].array == ["one", "two"]);
    }
}

///
unittest {
    import std.array:     array;
    import std.algorithm: sort, reverse;

    OMap!(int[string]) omap;

    omap["one"]   = 1;
    omap["two"]   = 2;
    omap["three"] = 3;

    // Usage is similar to an ordinary Associative Array
    assert(omap["three"] == 3);

    // Usage is similar to an ordinary array

    // It can be compared to ordinary AAs too
    assert(omap == ["one":1, "two":2, "three":3]);
    assert(omap == ["two":2, "three":3, "one":1]);

    // Slicing gives control over the ordered keys
    assert(omap[].array == ["one", "two", "three"]);

    reverse(omap[]);
    assert(omap[].array == ["three", "two", "one"]);

    sort(omap[]);
    assert(omap[].array == ["one", "three", "two"]);
    
}
