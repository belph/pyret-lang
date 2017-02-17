#lang pyret

provide *
provide-types *
import ast as A
import file as F
import string-dict as SD
import pprint as PP
import sets as S

import file("anf.arr") as N
import file("anf-loop-compiler.arr") as AL
import file("ast-anf.arr") as AA
import file("ast-util.arr") as AU
import file("compile-structs.arr") as C
import file("concat-lists.arr") as CL
import file("desugar.arr") as D
import file("desugar-check.arr") as CH
import file("js-ast.arr") as J

# Container for Static Analysis information to be utilized
# by compiler optimizations in anf-loop-compiler
data CompilerStaticInfo:
  | compiler-static-info(
      flatness-env :: SD.MutableStringDict<Option<Number>>,
      data-ordering :: SD.MutableStringDict<List<String>>)
sharing:
  method with-flatness(self, flatness-env):
    compiler-static-info(flatness-env, self.data-ordering)
  end,
  method with-data-ordering(self, data-ordering):
    compiler-static-info(self.flatness-env, data-ordering)
  end,
  method attach-to-object(self, object, mut):
    if mut:
      object.{
        flatness-env: self.flatness-env,
        data-ordering: self.data-ordering
      }
    else:
      object.{
        flatness-env: self.flatness-env.freeze(),
        data-ordering: self.data-ordering.freeze()
      }
    end
  end
end

fun init-compiler-static-info():
  compiler-static-info([SD.mutable-string-dict:], [SD.mutable-string-dict:])
end

fun detach-compiler-static-info(obj):
  compiler-static-info(obj.flatness-env, obj.data-ordering)
end

cl-empty = CL.concat-empty
cl-cons = CL.concat-cons

fun cl-map-sd(f, sd):
  for SD.fold-keys(acc from cl-empty, key from sd):
    cl-cons(f(key), acc)
  end
end

# TODO(joe): add methods for printing to module vs static information
data CompiledCodePrinter:
  | ccp-dict(dict :: SD.StringDict) with:
    method to-j-expr(self, d):
      J.j-parens(J.j-obj(for cl-map-sd(k from d):
          J.j-field(k, d.get-value(k))
        end))
    end,
    method pyret-to-js-static(self) -> String:
      self.to-j-expr(self.dict.remove("theModule")).to-ugly-source()
    end,
    method print-js-static(self, printer):
      self.to-j-expr(self.dict.remove("theModule")).print-ugly-source(printer)
    end,
    method pyret-to-js-pretty(self) -> PP.PPrintDoc:
      self.to-j-expr(self.dict).tosource()
    end,
    method pyret-to-js-runnable(self) -> String:
      self.to-j-expr(self.dict).to-ugly-source()
    end,
    method print-js-runnable(self, printer):
      self.to-j-expr(self.dict).print-ugly-source(printer)
    end
  | ccp(compiled :: J.JExpr) with:
    method pyret-to-js-pretty(self) -> PP.PPrintDoc:
      self.compiled.tosource()
    end,
    method pyret-to-js-runnable(self) -> String:
      self.compiled.to-ugly-source()
    end,
    method print-js-runnable(self, printer):
      self.compiled.print-ugly-source(printer)
    end
  | ccp-string(compiled :: String) with:
    method pyret-to-js-pretty(self) -> PP.PPrintDoc:
      PP.str(self.compiled)
    end,
    method pyret-to-js-runnable(self) -> String:
      self.compiled
    end,
    method print-js-runnable(self, printer):
      printer(self.compiled)
    end
  | ccp-file(path :: String) with:
    method pyret-to-js-pretty(self, width) -> String:
      raise("Cannot generate pretty JS from code string")
    end,
    method pyret-to-js-runnable(self) -> String block:
      F.file-to-string(self.path)
    end,
    method print-js-runnable(self, printer):
      printer(self.pyret-to-js-runnable())
    end
end

fun make-expr-data-env(
    aexpr :: AA.AExpr,
    static-info):
  cases(AA.AExpr) aexpr block:
    | a-type-let(_, bind, body) =>
      cases(AA.ATypeBind) bind block:
        | a-newtype-bind(_, typ, typt) =>
          print("Processing: [")
          print(torepr(typ))
          print(" (")
          print(typ.key())
          print("); ")
          print(torepr(typt))
          print(" (")
          print(typt.key())
          print(")]\n")
          cases(Option) static-info.type-name-to-variants.get-now(typt.key()):
            | some(vs) => static-info.data-ordering.set-now(typ.key(), vs.map(_.name))
            | none => nothing
          end
          static-info.namet-to-name.set-now(typt.key(), typ.key())
        | else => nothing
      end
      make-expr-data-env(body, static-info)
    | a-let(_, bind, val, body) => block:
        if AA.is-a-data-expr(val) block:
          # TODO (Philip): We can stash the info here
          print("make-expr-data-env[")
          print(torepr(bind))
          print("; ")
          print(torepr(val.name))
          print("; ")
          print(torepr(val.namet))
          print("]: ")
          print(val.variants.map(_.name))
          print("\n")
          static-info.type-name-to-variants.set-now(bind.id.key(), val.variants)
          cases(Option) static-info.namet-to-name.get-now(val.namet.key()):
            | some(n) => static-info.data-ordering.set-now(n, val.variants.map(_.name))
            | none => nothing
          end
          # TODO: static-info.type-name-to-aliases?
          # Make self-mapping entry so we know it's a "type" name
          static-info.alias-to-type-name.set-now(bind.id.key(), bind.id.key())
        else if AA.is-a-id-safe-letrec(val):
          # If we say
          # x = Type
          # y = x
          # z = y
          # We say z and y are aliases of x
          type-name-opt = static-info.alias-to-type-name.get-now(val.id.key())
          when is-some(type-name-opt):
            static-info.alias-to-type-name.set-now(bind.id.key(), type-name-opt.value)
          end
        else if AA.is-a-dot(val) and AA.is-a-id-safe-letrec(val.obj):
          # Check for: xyz = Type.is-variant or xyz = Type.flat-constructor
          type-name-opt = static-info.alias-to-type-name.get-now(val.obj.id.key())
          when is-some(type-name-opt):
            type-name = type-name-opt.value
            variants = static-info.type-name-to-variants.get-value-now(type-name)
            is-is-function = string-index-of(val.field, "is-") == 0
            when is-is-function or any(lam(v): v.name == val.field end, variants):
              static-info.flatness-env.set-now(bind.id.key(), some(0))
            end
          end
        else:
          none
        end
        make-lettable-data-env(val, static-info)
        make-expr-data-env(body, static-info)
      end
    | a-arr-let(_, bind, idx, e, body) => block:
        make-lettable-data-env(e, static-info)
        make-expr-data-env(body, static-info)
      end
    | a-var(_, bind, val, body) =>
      make-expr-data-env(body, static-info)
    | a-seq(_, lettable, expr) =>
      block:
        make-lettable-data-env(lettable, static-info)
        make-expr-data-env(expr, static-info)
      end
    | a-lettable(_, l) =>
      make-lettable-data-env(l, static-info)
  end
end

fun make-lettable-data-env(
    lettable :: AA.ALettable,
    static-info):
  default-ret = none
  cases(AA.ALettable) lettable:
    | a-module(_, answer, dv, dt, provides, types, checks) =>
      default-ret
    | a-if(_, c, t, e) =>
      block:
        make-expr-data-env(t, static-info)
        make-expr-data-env(e, static-info)
      end
    | a-assign(_, id, value) =>
      block:
        when AA.is-a-id(value) block:
          when static-info.flatness-env.has-key-now(value.id.key()):
            static-info.flatness-env.set-now(id.key(), static-info.flatness-env.get-value-now(value.id.key()))
          end

          when static-info.alias-to-type-name.has-key-now(value.id.key()):
            val-type = static-info.alias-to-type-name.get-value-now(value.id.key())
            static-info.alias-to-type-name.set-now(id.key(), val-type)
          end
        end

        when AA.is-a-id-safe-letrec(value):
          type-name-opt = static-info.alias-to-type-name.get-now(value.id.key())
          when is-some(type-name-opt):
            static-info.alias-to-type-name.set-now(id.key(), type-name-opt.value)
          end
        end
      end
    | a-app(_, f, args, _) => default-ret
    | a-method-app(_, obj, meth, args) => default-ret
    | a-prim-app(_, f, args) => default-ret
    | a-ref(_, ann) => default-ret
    | a-tuple(_, fields) => default-ret
    | a-tuple-get(_, tup, index) => default-ret
    | a-obj(_, fields) => default-ret
    | a-update(_, supe, fields) => default-ret
    | a-extend(_, supe, fields) => default-ret
    | a-dot(_, obj, field) => default-ret
    | a-colon(_, obj, field) => default-ret
    | a-get-bang(_, obj, field) => default-ret
    | a-lam(_, name, args, ret, body) => default-ret
    | a-method(_, name, args, ret, body) => default-ret
    | a-id-var(_, id) => default-ret
    | a-id-letrec(_, id, safe) => default-ret
    | a-id-safe-letrec(_, id) => default-ret
    | a-val(_, v) => default-ret
    | a-data-expr(l, name, namet, vars, shared) => default-ret
    | a-cases(_, typ, val, branches, els) => block:
        print("\nmake-lettable-data-env: ")
        print(typ)
        print("\n")
        visit-branch = lam(case-branch):
          make-expr-data-env(case-branch.body, static-info)
        end
        each(visit-branch, branches)
        make-expr-data-env(els, static-info)
      end
  end
end


fun flatness-max(a :: Option<Number>, b :: Option<Number>) -> Option<Number>:
  # read the docs, maybe there's a quicker way to write this
  cases (Option) a:
    | some(a-val) =>
      cases (Option) b:
        | some(b-val) =>
          some(num-max(a-val, b-val))
        | none => none
      end
    | none => none
  end
end

# Maybe compress Option<Number> into a type like FlatnessInfo or something (maybe something without "Info" in the name)
fun make-expr-flatness-env(
    aexpr :: AA.AExpr,
    static-info) -> Option<Number>:
  cases(AA.AExpr) aexpr:
    | a-type-let(_, bind, body) =>
      make-expr-flatness-env(body, static-info)
    | a-let(_, bind, val, body) =>
      val-flatness = if AA.is-a-lam(val) or AA.is-a-method(val) block:
        lam-flatness = make-expr-flatness-env(val.body, static-info)
        static-info.flatness-env.set-now(bind.id.key(), lam-flatness)
        # flatness of defining this lambda is 0, since we're not actually
        # doing anything with it
        some(0)
      else if AA.is-a-id-safe-letrec(val):
        block:
          # If we're binding this name to something that's already been defined
          # just copy over the definition
          known-flatness-opt = static-info.flatness-env.get-now(val.id.key())
          cases (Option) known-flatness-opt:
            | some(flatness) => static-info.flatness-env.set-now(bind.id.key(), flatness)
            | none => none
          end
          # flatness of the binding part of the let is 0 since we don't
          # call anything
          some(0)
        end
      else:
        make-lettable-flatness-env(val, static-info)
      end

      # Compute the flatness of the body
      body-flatness = make-expr-flatness-env(body, static-info)

      flatness-max(val-flatness, body-flatness)
    | a-arr-let(_, bind, idx, e, body) =>
      # Could maybe try to add some string like "bind.name + idx" to the
      # sd to let us keep track of the flatness if e is an a-lam, but for
      # now we don't since I'm not sure it'd work right.
      flatness-max(make-lettable-flatness-env(e, static-info), make-expr-flatness-env(body, static-info))
    | a-var(_, bind, val, body) =>
      # Do same thing with a-var as with a-let for now
      make-expr-flatness-env(body, static-info)
    | a-seq(_, lettable, expr) =>
      a-flatness = make-lettable-flatness-env(lettable, static-info)
      b-flatness = make-expr-flatness-env(expr, static-info)
      flatness-max(a-flatness, b-flatness)
    | a-lettable(_, l) => make-lettable-flatness-env(l, static-info)
  end
end

fun get-flatness-for-call(function-name :: String, sd :: SD.MutableStringDict<Option<Number>>) -> Option<Number>:
  # Look up flatness in the dictionary
  fun inc-flatness(flat-opt :: Option<Number>):
    flat-opt.and-then(lam(x): x + 1 end)
  end

  # If it's not in our lookup dict OR the flatness is none treat it the same
  val = sd.get-now(function-name).or-else(none)
  cases (Option) val:
    | some(flatness) => some(flatness + 1)
    | none => none
  end
end

fun make-lettable-flatness-env(
    lettable :: AA.ALettable,
    static-info) -> Option<Number>:
  default-ret = some(0)
  cases(AA.ALettable) lettable:
    | a-module(_, answer, dv, dt, provides, types, checks) =>
      default-ret
    | a-if(_, c, t, e) =>
      flatness-max(make-expr-flatness-env(t, static-info), make-expr-flatness-env(e, static-info))

    # NOTE -- a-assign might not be flat b/c it checks annotations
    | a-assign(_, id, value) =>
      block:
        when AA.is-a-id(value) and static-info.flatness-env.has-key-now(value.id.key()):
          static-info.flatness-env.set-now(id.key(), static-info.flatness-env.get-value-now(value.id.key()))
        end
        default-ret
      end
    | a-app(_, f, args, _) =>
      # Look up flatness in the dictionary
      if AA.is-a-id(f):
        get-flatness-for-call(f.id.key(), static-info.flatness-env)
      else:
        # This should never happen in a "correct" program, but it's not our job
        # to do this kind of checking here, so don't raise an error.
        none
      end
    | a-method-app(_, obj, meth, args) =>
      # For now method calls are infinite flatness
      none
    | a-prim-app(_, f, args) => get-flatness-for-call(f, static-info.flatness-env)
      # TODO: Treat prim-app as flat
      # Not worrying about these cases yet, though if they all deal with values, should be trivial
    | a-ref(_, ann) => default-ret
    | a-tuple(_, fields) => default-ret
    | a-tuple-get(_, tup, index) => default-ret
    | a-obj(_, fields) => default-ret

    # NOTE -- update might not be flat b/c it checks annotations
    | a-update(_, supe, fields) => default-ret
    | a-extend(_, supe, fields) => default-ret
    | a-dot(_, obj, field) => default-ret
    | a-colon(_, obj, field) => default-ret
    | a-get-bang(_, obj, field) =>
      default-ret
    | a-lam(_, name, args, ret, body) => default-ret
    | a-method(_, name, args, ret, body) =>
      default-ret
    | a-id-var(_, id) =>
      default-ret
    | a-id-letrec(_, id, safe) =>
      default-ret
    | a-id-safe-letrec(_, id) =>
      default-ret
    | a-val(_, v) =>
      default-ret
    | a-data-expr(l, name, namet, vars, shared) =>
      default-ret
    # NOTE -- cases might not be flat b/c it checks annotations
    | a-cases(_, typ, val, branches, els) => block:
      print("make-lettable-flatness-env<cases>: ")
      print(typ)
      print("\n")
      # Flatness is the max of the flatness all the cases branches
      combine = lam(case-branch, max-flat):
        branch-flatness = make-expr-flatness-env(case-branch.body, static-info)
        flatness-max(max-flat, branch-flatness)
      end
      max-flat = branches.foldl(combine, some(0))

      else-flat = make-expr-flatness-env(els, static-info)
        flatness-max(max-flat, else-flat)
      end
  end
end

fun make-prog-flatness-env(anfed :: AA.AProg, bindings :: SD.MutableStringDict<C.ValueBind>, env :: C.CompileEnvironment) block:

  static-info = init-compiler-static-info()

  for SD.each-key-now(k from bindings):
    vb = bindings.get-value-now(k)
    when C.is-bo-module(vb.origin) block:
      print("Processing binding ")
      print(k)
      print(": ")
      print(vb)
      print("\n")
      cases(Option) vb.origin.mod block:
        | none =>
          when A.is-s-global(vb.atom) block:
            name = vb.atom.toname()
            uri = env.globals.values.get-value(name)
            provides-opt = env.mods.get(uri)
            cases (Option) provides-opt block:
              | none => nothing
              | some(provides) =>
                ve = provides.values.get-value(name)
                print("\tHAS VALUE EXPORT: ")
                print(ve)
                print("\n")
                cases(C.ValueExport) ve:
                  | v-fun(_, _, flatness) => static-info.flatness-env.set-now(vb.atom.key(), flatness)
                  | else => nothing
                end
            end
          end
        | some(import-type) =>
          dep = AU.import-to-dep(import-type).key()
          cases(Option) env.mods.get(dep) block:
            | none => raise("There is a binding whose module is not in the compile env: " + to-repr(k) + " " + to-repr(import-type))
            | some(provides) =>
              exported-as = vb.atom.toname()
              value-export = provides.values.get-value(exported-as)
              # TODO (Philip): Can we toss in the variant info here?
              print("\tHAS VALUE EXPORT: ")
              print(value-export)
              print("\n")
              cases(C.ValueExport) value-export:
                | v-fun(_, _, flatness) =>
                  static-info.flatness-env.set-now(k, flatness)
                | v-just-type(t) => block:
                    cases (Option) provides.data-definitions.get(exported-as) block:
                      | some(x) =>
                        print("Some: ")
                        print(x)
                        print(" [")
                        print(t)
                        print("]")
                        print("\n")
                      | none =>
                        print("None: ")
                        print("[")
                        print(t)
                        print("]\n")
                    end
                  end
                | else =>
                  nothing
              end
          end
      end
    end
  end

  final-static-info = cases(AA.AProg) anfed:
    | a-program(_, prov, imports, body) => block:
        annotated-static-info = static-info.attach-to-object({
            type-name-to-variants: SD.make-mutable-string-dict(),
            alias-to-type-name: SD.make-mutable-string-dict(),
            namet-to-name: SD.make-mutable-string-dict()
          }, true)
        make-expr-data-env(body, annotated-static-info)
        make-expr-flatness-env(body, annotated-static-info)
        #print("flatness env: " + tostring(sd) + "\n\n")
        detach-compiler-static-info(annotated-static-info)
      end
  end
  for SD.each-key-now(k from final-static-info.data-ordering) block:
    print("Data ordering of '")
    print(k)
    print("': ")
    print(final-static-info.data-ordering.get-value-now(k))
    print("\n")
  end
  #print("flatness env: " + tostring(flatness-env) + "\n")
  #compiler-static-info(flatness-env.flatness.freeze(), flatness-env.data-ordering.freeze())
  final-static-info
end


fun get-defined-values(ast):
  fun help(ae):
    cases(AA.AExpr) ae:
      | a-type-let(_, _, body) => help(body)
      | a-let(_, _, _, body) => help(body)
      | a-arr-let(_, _, _, _, body) => help(body)
      | a-var(_, _, _, body) => help(body)
      | a-seq(_, _, e2) => help(e2)
      | a-lettable(_, e) =>
        block:
          when not(AA.is-a-module(e)):
            raise("Ill-formed ANF ast: " + torepr(e))
          end
          e
        end
    end
  end

  the-module = help(ast.body)
  the-dvs = the-module.defined-values

  dvs-dict = for fold(s from [SD.string-dict:], d from the-dvs):
    cases(AA.ADefinedValue) d:
      | a-defined-value(name, val) => s.set(name, val.id.key())
      | a-defined-var(name, id) => s.set(name, id.key())
    end
  end

  dvs-dict
end

fun get-flat-provides(provides, flatness-env, ast) block:
  dvs-dict = get-defined-values(ast)
  cases(C.Provides) provides block:
    | provides(uri, values, aliases, datatypes) =>
      new-values = for SD.fold-keys(s from [SD.string-dict:], k from values):
        maybe-flatness = flatness-env.get(dvs-dict.get-value(k))
        existing-val = values.get-value(k)
        new-val = cases(Option) maybe-flatness:
          | none => existing-val
          | some(flatness-result) =>
            cases(Option) flatness-result:
              | none => existing-val
              | some(flatness) => C.v-fun(existing-val.t, k, some(flatness))
            end
        end
        s.set(k, new-val)
      end
      C.provides(uri, new-values, aliases, datatypes)
  end
end

# Visitor which collects information about
# each variant definition and creates a statically-known
# ordering
fun collect-data-ordering(anfed) block:
  ordering = [SD.mutable-string-dict:]
  data-ordering-visitor = AA.default-map-visitor.{
    # NOTE (Philip): This defines the canonical ordering
    #                for cases expressions associated with
    #                this type.
    method a-data-expr(self, l :: A.Loc, name :: String, namet :: A.Name, variants :: List<AA.AVariant>, shared :: List<AA.AField>) block:
      # NOTE (Philip): We can insert more sophisticated
      #                static information here in the future
      #                (such as constructor arity) if desired.
      print(namet.key())
      print("\n")
      ordering.set-now(namet.key(), variants.map(_.name))
      AA.a-data-expr(l, name, namet, variants.map(_.visit(self)), shared.map(_.visit(self)))
    end
  }
  anfed.visit(data-ordering-visitor)
  ordering.freeze()
end

fun trace-make-compiled-pyret(add-phase, program-ast, env, bindings, provides, options)
  -> { C.Provides; C.CompileResult<CompiledCodePrinter> } block:
  anfed = add-phase("ANFed", N.anf-program(program-ast))
  static-env = add-phase("Build flatness env", make-prog-flatness-env(anfed, bindings, env))
  flat-provides = add-phase("Get flat-provides", get-flat-provides(provides, static-env.flatness-env.freeze(), anfed))
  compiled = anfed.visit(AL.splitting-compiler(env, add-phase, static-env, flat-provides, options))
  {flat-provides; add-phase("Generated JS", C.ok(ccp-dict(compiled)))}
end

fun println(s) block:
  print(s + "\n")
end

fun make-compiled-pyret(program-ast, env, bindings, provides, options) -> { C.Provides; CompiledCodePrinter} block:
  #  each(println, program-ast.tosource().pretty(80))
    anfed = N.anf-program(program-ast)
  #each(println, anfed.tosource().pretty(80))
  static-env = make-prog-flatness-env(anfed, bindings, env)
  flat-provides = get-flat-provides(provides, static-env.flatness-env.freeze(), anfed)
  compiled = anfed.visit(AL.splitting-compiler(env, static-env, flat-provides, options))
  {flat-provides; ccp-dict(compiled)}
end
