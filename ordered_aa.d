import std.traits;

/**
 * Ordered Associative Array modeled from Python's OrderedDict.
 *
 * Subtypes built-in associative arrays.
 *
 * It works by using an array to keep the key order in addition to a regular
 * associative array.
 */
struct OrderedAA(T) if (isAssociativeArray!T) {
    import std.algorithm;
    import std.typecons;

    alias KeyType!T   keyT;
    alias ValueType!T valueT;

    private keyT[] _order;
    private T      _aa;

    alias _aa this;

    /**
     * Associative Array based Constructor
     */
    this(T base) {
        _order.reserve(base.length);

        foreach (key, value ; base) {
            _order   ~= key;
            _aa[key]  = value;
        }
    }

    ///
    unittest {
        auto aa  = ["one": 1, "two": 2];
        auto oaa = OrderedAA(aa);
        assert(oaa == aa);
    }

    /**
     * Ordered Associative Array based Constructor
     */
    this(OrderedAA!T base) {
        _order.reserve(base.length);

        foreach (key, value ; base.byKeyValue) {
            _order   ~= key;
            _aa[key]  = value;
        }
    }

    ///
    unittest {
        auto oaa_1 = OrderedAA(["one": 1, "two": 2]);
        auto oaa_2 = OrderedAA(oaa_1);
        assert(oaa_1 == oaa_2);
    }

    /**
     * Remove all contents from the container.
     */
    void clear() {
        _aa    = null;
        _order = null;
    }

    ///
    unittest {
        auto oaa = OrderedAA(["one": 1, "two": 2]);
        oaa.clear;
        assert(oaa[].length == 0);
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
        return _order.map!(x => _aa[x]);
    }

    /**
     * Returns a range of tuples (key, value) in order
     */
    auto byKeyValue() {
        return _order.map!(x => tuple(x, _aa[x]));
    }

    auto ref opIndex() {
        return _order[];
    }

    auto ref opIndex(const keyT key) {
        return _aa[key];
    }

    void opIndexAssign(const valueT value, const keyT key) {
        if (key !in _aa)
            _order ~= key;
        _aa[key] = value;
    }

    /**
     * Remove an element in place given its key
     * Returns false if the element wasn't in the array, true otherwise
     */
    bool remove(const keyT key) {
        size_t index = _order.countUntil(key);

        if (index == -1)
            return false;

        _order = std.algorithm.remove(_order, index);
        _aa.remove(key);
        return true;
    }

    ///
    unittest {
        import std.array:     array;
        import std.algorithm: sort;

        auto aa = OrderedAA(["one": 1, "two": 2, "three": 3]);

        sort(aa[]);
        assert(aa[].array == ["one", "three", "two"]);

        assert(!aa.remove("four"));
        assert(aa[].array == ["one", "three", "two"]);

        assert(aa.remove("three"));
        assert(aa[].array == ["one", "two"]);
    }
}

///
unittest {
    import std.array:     array;
    import std.algorithm: sort, reverse;

    OrderedAA!(int[string]) aa;

    aa["one"]   = 1;
    aa["two"]   = 2;
    aa["three"] = 3;

    // Usage is similar to an ordinary Associative Arrays
    assert(aa["three"] == 3);

    // It can be compared to ordinary AAs too
    assert(aa == ["one":1, "two":2, "three":3]);
    assert(aa == ["two":2, "three":3, "one":1]);

    // Slicing gives control over the ordered keys
    assert(aa[].array == ["one", "two", "three"]);

    reverse(aa[]);
    assert(aa[].array == ["three", "two", "one"]);

    sort(aa[]);
    assert(aa[].array == ["one", "three", "two"]);
}


