({
  requires: [ ],
  provides: {
    shorthands: {
      "AnyPred":  ["arrow", ["Any"], "Boolean"],
      "AnyPred2": ["arrow", ["Any", "Any"], "Boolean"],
      "NumPred":  ["arrow", ["Number"], "Boolean"],
      "NumPred2": ["arrow", ["Number", "Number"], "Boolean"],
      "NumBinop": ["arrow", ["Number", "Number"], "Number"],
      "NumUnop":  ["arrow", ["Number"], "Number"],
      "StrPred":  ["arrow", ["String"], "Boolean"],
      "StrPred2": ["arrow", ["String", "String"], "Boolean"],
      "StrBinop": ["arrow", ["String", "String"], "String"],
      "StrUnop":  ["arrow", ["String"], "String"],
      "tva":      ["tid", "a"],
      "tvb":      ["tid", "b"],
      "tvc":      ["tid", "c"],
      "tvd":      ["tid", "d"],
      "tve":      ["tid", "e"],
      "Equality": { tag: "name", 
                    origin: { "import-type": "uri", uri: "builtin://equality" },
                    name: "EqualityResult" }
    },
    values: {
      "nothing": "Nothing",
      "torepr": ["arrow", ["Any"], "String"],
      "tostring": ["arrow", ["Any"], "String"],
      "not": ["arrow", ["Boolean"], "Boolean"],

      "is-nothing": "AnyPred",
      "is-number": "AnyPred",
      "is-string": "AnyPred",
      "is-boolean": "AnyPred",
      "is-object": "AnyPred",
      "is-function": "AnyPred",
      "is-raw-array": "AnyPred",

      // Array functions
      "raw-array":         ["forall", ["a"], ["Maker", "tva", ["RawArray", "tva"]]],
      "raw-array-get":     ["forall", ["a"], ["arrow", [["RawArray", "tva"], "Number"], "tva"]],
      "raw-array-set":     ["forall", ["a"], ["arrow", [["RawArray", "tva"], "Number", "tva"], 
                                              ["RawArray", "tva"]]],
      "raw-array-of":      ["forall", ["a"], ["arrow", ["tva", "Number"], ["RawArray", "tva"]]],
      "raw-array-length":  ["forall", ["a"], ["arrow", [["RawArray", "tva"]], "Number"]],
      "raw-array-to-list": ["forall", ["a"], ["arrow", [["RawArray", "tva"]], ["List", "tva"]]],
      "raw-array-fold":    ["forall", ["a", "b"], ["arrow", [["arrow", ["tvb", "tva", "Number"], "tvb"], 
                                                             "tvb", ["RawArray", "tva"], "Number"], "tvb"]],

      // Equality functions

      "equal-always3": ["arrow", ["Any", "Any"], "Equality"],
      "equal-now3":    ["arrow", ["Any", "Any"], "Equality"],
      "identical3":    ["arrow", ["Any", "Any"], "Equality"],
      "equal-always": "AnyPred2",
      "equal-now": "AnyPred2",
      "identical": "AnyPred2",
      "within": ["arrow", ["Number"], "AnyPred2"],
      "within-abs": ["arrow", ["Number"], "AnyPred2"],
      "within-rel": ["arrow", ["Number"], "AnyPred2"],
      "within-now": ["arrow", ["Number"], "AnyPred2"],
      "within-abs-now": ["arrow", ["Number"], "AnyPred2"],
      "within-rel-now": ["arrow", ["Number"], "AnyPred2"],

      // Number functions

      "string-to-number": ["arrow", ["String"], ["Option", "Number"]],
      "num-is-integer": "NumPred",
      "num-is-rational": "NumPred",
      "num-is-roughnum": "NumPred",
      "num-is-positive": "NumPred",
      "num-is-negative": "NumPred",
      "num-is-non-positive": "NumPred",
      "num-is-non-negative": "NumPred",
      "num-is-fixnum": "NumPred",

      "num-min": "NumBinop",
      "num-max": "NumBinop",
      "num-equal": "NumPred2",
      "num-within": ["arrow", ["Number"], "NumPred2"],
      "num-within-abs": ["arrow", ["Number"], "NumPred2"],
      "num-within-rel": ["arrow", ["Number"], "NumPred2"],

      "num-abs": "NumUnop",
      "num-sin": "NumUnop",
      "num-cos": "NumUnop",
      "num-tan": "NumUnop",
      "num-asin": "NumUnop",
      "num-acos": "NumUnop",
      "num-atan": "NumUnop",

      "num-modulo": "NumBinop",

      "num-truncate": "NumUnop",
      "num-sqrt": "NumUnop",
      "num-sqr": "NumUnop",
      "num-ceiling": "NumUnop",
      "num-floor": "NumUnop",
      "num-round": "NumUnop",
      "num-round-even": "NumUnop",
      "num-log": "NumUnop",
      "num-exp": "NumUnop",
      "num-exact": "NumUnop",
      "num-to-rational": "NumUnop",
      "num-to-roughnum": "NumUnop",
      "num-to-fixnum": "NumUnop",

      "num-expt": "NumBinop",
      "num-tostring": ["arrow", ["Number"], "String"],
      "num-to-string": ["arrow", ["Number"], "String"],
      "num-to-string-digits": ["arrow", ["Number", "Number"], "String"],

      "random": "NumUnop",
      "num-random": "NumUnop",
      "num-random-seed": ["arrow", ["Number"], "Nothing"],

      // Time functions

      "time-now": ["arrow", [], "Number"],

      // String functions

      "gensym": ["arrow", [], "String"],
      "string-repeat": ["arrow", ["String", "Number"], "String"],
      "string-substring": ["arrow", ["String", "Number", "Number"], "String"],
      "string-toupper": "StrUnop",
      "string-tolower": "StrUnop",
      "string-append": "StrBinop",
      "string-equal": "StrPred2",
      "string-contains": "StrPred2",
      "string-isnumber": "StrPred",
      "string-to-number": ["arrow", ["String"], ["Option", "Number"]],
      "string-length": ["arrow", ["String"], "Number"],
      "string-replace": ["arrow", ["String", "String", "String"], "String"],
      "string-char-at": ["arrow", ["String", "Number"], "String"],
      "string-to-code-point": ["arrow", ["String"], "Number"],
      "string-from-code-point": ["arrow", ["Number"], "String"],
      "string-to-code-points": ["arrow", ["String"], ["List", "Number"]],
      "string-from-code-points": ["arrow", [["List", "Number"]], "String"],
      "string-split": ["arrow", ["String", "String"], ["List", "String"]],
      "string-split-all": ["arrow", ["String", "String"], ["List", "String"]],
      "string-explode": ["arrow", ["String"], ["List", "String"]],
      "string-index-of": ["arrow", ["String", "String"], "Number"],

    },
    aliases: {
      "Any": "tany"
    },
    datatypes: {
      "Number": ["data", "Number", [], [], {}],
      "Exactnum": ["data", "Exactnum", [], [], {}],
      "Roughnum": ["data", "Roughnum", [], [], {}],
      "NumInteger": ["data", "NumInteger", [], [], {}],
      "NumRational": ["data", "NumRational", [], [], {}],
      "NumPositive": ["data", "NumPositive", [], [], {}],
      "NumNegative": ["data", "NumNegative", [], [], {}],
      "NumNonPositive": ["data", "NumNonPositive", [], [], {}],
      "NumNonNegative": ["data", "NumNonNegative", [], [], {}],
      "String": ["data", "String", [], [], {}],
      "Function": ["data", "Function", [], [], {}],
      "Boolean": ["data", "Boolean", [], [], {}],
      "Object": ["data", "Object", [], [], {}],
      "Method": ["data", "Method", [], [], {}],
      "Nothing": ["data", "Nothing", [], [], {}],
      "RawArray": ["data", "RawArray", ["a"], [], {}]
    }
  },
  nativeRequires: [ ],
  theModule: function(runtime, namespace, uri /* intentionally blank */) {
    return runtime.globalModuleObject;
  }
})