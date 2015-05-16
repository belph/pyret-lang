## Basic XML Library
## Philip Blair (belph)
## 
## Methods:
## _torepr  : Pretty display suitable for pasting into
##              an XML document
## tosource : String-escaped display suitable for processing
##              (e.g. in Javascript)
##
## Visual Glossary:
## 
##          Attribute                 Atomic
##              |                       |
##    +---------+----------+       +----+------+
## <p style="align: center;"><span>Hello, world!</span></p>
##  |                          +-----Element(tag)--+     |
##  +--------------------Element(tag)--------------------+

provide {
  attribute: attribute,
  tag: tag,
  atomic: atomic
} end
provide-types *

import pprint as PP

PRETTY-WIDTH = 80

fun ensure-quoted(str :: String) :
  if (string-char-at(str, 0) == "\"") and (string-char-at(str,string-length(str) - 1) == "\"") :
    str
  else:
    "\"" + str + "\""
  end
end

data Attribute:
  | attribute(name :: String, value) with:
    _torepr(self, shadow torepr):
      if (is-number(self.value) and not(num-is-integer(self.value))):
        PP.str(self.name + "=" + ensure-quoted(num-to-string-digits(self.value, 10))).pretty(PRETTY-WIDTH).join-str("\n")
      else:
        PP.str(self.name + "=" + ensure-quoted(torepr(self.value))).pretty(PRETTY-WIDTH).join-str("\n")
      end
    end,
    tosource-help(self):
      self.tosource()
    end,
    tosource(self):
      if (is-number(self.value) and not(num-is-integer(self.value))):
        self.name + "=" + ensure-quoted(num-to-string-digits(self.value, 10))
      else:
        self.name + "=" + ensure-quoted(torepr(self.value))
      end
    end
end

data Element:
  | tag(name :: String, attributes :: List<Attribute>, elts :: List<Element>) with:
    get-att-string-help(self):
      if is-link(self.attributes):
        for fold(acc from "", a from self.attributes): acc + " " + tostring(torepr(a)) end
      else:
        ""
      end
    end,
    get-att-string(self):
      if is-link(self.attributes):
        self.get-att-string-help()
      else:
        ""
      end
    end,
    get-rest-string(self):
      if is-link(self.elts):
        PP.str(">") + 
        PP.str(fold(string-append, "", 
            map(lam(a): a.tosource-help() end, self.elts)) + 
          "</" + self.name) + 
        PP.str(">")
      else:
        PP.str("/>")
      end
    end,
    tosource-help(self):
      self.tosource()
    end,
    _torepr(self, shadow torepr):
      fun map-concat-last(lst :: List, last :: String):
        cases(List) lst:
          | empty => empty
          | link(first,rest) => 
            if is-empty(rest):
              link(PP.str(torepr(first) + last),empty)
            else:
              link(PP.str(torepr(first)),map-concat-last(rest,last))
            end
        end
      end
      close-start-tag = if is-link(self.elts): ">" else: "/>" end
      start-tag = 
        if is-link(self.attributes):
          PP.surround(2, 0, PP.str("<" + self.name + " "), PP.flow(
              self.attributes.map(lam(a): PP.str(torepr(a)) end)), PP.str(close-start-tag))
        else:
          PP.str("<" + self.name + close-start-tag)
        end
        
      end-tag =
        if is-link(self.elts): PP.str("</" + self.name + ">")
        else: PP.str("")
        end
      body = PP.align(PP.vert(self.elts.map(lam(x): PP.str(torepr(x)) end)))
      PP.surround(2, 0, start-tag, body, end-tag).pretty(PRETTY-WIDTH).join-str("\n")
    end,
    tosource(self):
      (PP.str("<") + PP.str(self.name) + PP.str(self.get-att-string()) + self.get-rest-string()).pretty(40).join-str("\n")
    end
  | atomic(val) # Any Atomic Value (Strings, Numbers, etc.)
    with:
    _torepr(self, shadow torepr):
      if (is-number(self.val) and not(num-is-integer(self.val))):
        PP.str(num-to-string-digits(self.val, 10)).pretty(PRETTY-WIDTH).join-str("\n")
      else:
        PP.str(tostring(self.val)).pretty(PRETTY-WIDTH).join-str("\n")
      end
    end,
    tosource-help(self):
      if (is-number(self.val) and not(num-is-integer(self.val))):
        num-to-string-digits(self.val, 10)
      else:
        tostring(self.val)
      end
    end,
    tosource(self):
      if (is-number(self.val) and not(num-is-integer(self.val))):
        num-to-string-digits(self.val, 10)
      else:
        torepr(self.val)
      end
    end
end
