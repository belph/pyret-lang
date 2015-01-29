## Basic XML Library
## Philip Blair (belph)

provide {
  attribute: attribute,
  tag: tag,
  atomic: atomic
} end
provide-types *

import pprint as PP

data Attribute:
  | attribute(name :: String, value) with:
    _torepr(self, shadow torepr):
      vrep = torepr(self.value)
      if is-string(vrep):
        self.name + "=" + vrep
      else:
        self.name + "=\"" + torepr(self.value) + "\""
      end
    end,
    tosource(self):
      PP.infix(2, 1, PP.str("="), PP.str(self.name), PP.str(torepr(self.value)))
    end
end

data Element:
  | tag(name :: String, attributes :: List<Attribute>, elts :: List<Element>) with:
    get-att-string(self):
      if is-link(self.attributes):
        for fold(acc from "", a from self.attributes): acc + " " + torepr(a) end
      else:
        ""
      end
    end,
    get-rest-string(self):
      if is-link(self.elts):
        ">" + fold(string-append, "", map(torepr, self.elts)) + "</" + self.name + ">"
      else:
        "/>"
      end
    end,
    _torepr(self, shadow torepr):      
      "<" + self.name + self.get-att-string() + self.get-rest-string()
    end,
    tosource(self):
      start-tag = PP.soft-surround(2, 1, PP.str("<" + self.name), PP.flow(self.attributes.map(_.tosource())),
        if is-link(self.elts): PP.str(">")
        else: PP.str("/>")
        end)
      end-tag =
        if is-link(self.elts): PP.str("</" + self.name + ">")
        else: PP.str("")
        end
      body = PP.nest(2, PP.vert(self.elts.map(_.tosource())))
      PP.soft-surround(2, 1, start-tag, body, end-tag)
    end
  | atomic(val) # Any Atomic Value (Strings, Numbers, etc.)
    with:
    _torepr(self, shadow torepr):
      torepr(self.val)
    end,
    tosource(self):
      PP.str(torepr(self.val))
    end
end