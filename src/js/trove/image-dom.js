define([
    "js/runtime-util",
    "js/js-numbers",
    "js/ffi-helpers"
  ], function(utils, jsnums, ffiLib) {
  return utils.memoModule("image-dom", function(runtime, namespace) {
    return runtime.loadJSModules(namespace, [ffiLib], function(ffi) {
    
    // Predicate creator
    var p = function(pred, name) {
        return function(val) { runtime.makeCheckType(pred, name)(val); return val; }
    }
    
    var checkString = p(runtime.isString, "String");
    var checkReal = p(function(val) {
        return runtime.isNumber(val) && jsnums.isReal(val); }, "Real Number");

    /* Keeping this around just in case, but I think that
       the non-jQuery version *should* work
    function createElementJQuery(tag, maybeNS) {
        var NSProvided = (typeof maybeNS === "string");
        var validTag = (typeof tag === "string")
            && (tag.match(/[A-Za-z0-9]+/) !== null);
        if (!validTag) {
            // This function will only be called by SVGWrapper(), so
            // we can throw a standard JS error here
            throw "Invalid tag: " + tag;
        }
        var nsString = "";
        if (NSProvided) {
            nsString = " xmlns=\"" + maybeNS + "\"";
        }
        return jQuery('<' + tag + nsString + '></' + tag + '>');
    }*/
    
    var SVGWrapper = function() {
            this.svgElt = document.createElementNS("http://www.w3.org/2000/svg", "svg");
            this.svgElt.setAttribute("width", "0");
            this.svgElt.setAttribute("height", "0");
            this.svgElt.setAttribute("visibility", "hidden");
            window.document.body.appendChild(this.svgElt);
            var g = window.document.createElementNS(svgns, "g");
            g.setAttribute("visibility", "hidden");
            this.group = this.svgElt.appendChild(g);
            this.setContents = function(contents) { g.innerHTML = contents; };
            this.getCorners = function() {
                var bbox = this.group.getBBox();
                var topLeft = runtime.makeObject({ "x" : runtime.wrap(bbox.x),
                                                   "y" : runtime.wrap(bbox.y)});
                var botRight = runtime.makeObject({ "x" : runtime.wrap(bbox.x + bbox.width),
                                                    "y" : runtime.wrap(bbox.y + bbox.height)});
                return runtime.makeObject({ "topLeft" : topLeft, "botRight" : botRight });
            }
            this.tearDown = function() {
                this.svgElt.removeChild(this.group);
                window.document.body.removeChild(this.svgElt);
            }
        }
    var textBoundingBoxCorners = function(rawTextStr, rawStyle, xPos, yPos, rawTransforms) {
        var wrap = new SVGWrapper();
        // Credit to bobince on SO for sanitize()
        var sanitize = function (s) {
            return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
        };
        var textStr = sanitize(rawtextStr);
        var style = sanitize(rawstyle);
        var transforms = sanitize(rawtransforms);
        var svgText = "<text x=\"" + xPos + "\" y=\"" + yPos
                + "\" style=\"" + style + "\" transform=\""
                + transforms + "\">" + textStr + "</text>";
        console.log(svgText);
        wrap.setContents(svgText);
        var ret = wrap.getCorners();
        wrap.tearDown();
        return ret;
    }
    
    var f = runtime.makeFunction;
    
    return runtime.makeObject({
      "provide": runtime.makeObject({
        "text-svg-bounding-box": f(function(maybeText, maybeStyle, maybeX, maybeY, maybeTrans) {
        ffi.checkArity(5, arguments, "text-svg-bounding-box");
        var text = checkString(maybeText);
        var style = checkString(maybeStyle);
        var x = checkReal(maybeX);
        var y = checkReal(maybeY);
        var trans = checkString(maybeTrans);
        return textBoundingBoxCorners(text, style, x, y, trans);
        })})});
    })})})
          
          
        