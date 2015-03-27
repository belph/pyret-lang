define(["js/secure-loader", "js/ffi-helpers", "js/runtime-anf", "trove/checker", "js/dialects-lib", "js/runtime-util"], function(loader, ffi, runtimeLib, checkerLib, dialectsLib, util) {

  if(util.isBrowser()) {
    var rjs = requirejs;
    var define = window.define;
  }
  else {
    var rjs = require("requirejs");
    var define = rjs.define;
  }

  return function(RUNTIME, NAMESPACE) {
    var F = ffi(RUNTIME, NAMESPACE);

    function execWithDir(jsStr, modnameP, loaddirP, checkAllP, dialectP, params) {
      F.checkArity(6, arguments, "exec");
      RUNTIME.checkString(jsStr);
      RUNTIME.checkString(modnameP);
      RUNTIME.checkString(loaddirP);
      RUNTIME.checkBoolean(checkAllP);
      RUNTIME.checkString(dialectP);
      var str = RUNTIME.unwrap(jsStr);
      var modname = RUNTIME.unwrap(modnameP);
      var loaddir = RUNTIME.unwrap(loaddirP);
      var checkAll = RUNTIME.unwrap(checkAllP);
      var dialect = RUNTIME.unwrap(dialectP);
      var argsArray = F.toArray(params).map(RUNTIME.unwrap);
      return exec(str, modname, loaddir, checkAll, dialect, argsArray);
    }

    function exec(str, modname, loaddir, checkAll, dialect, args) {
      var name = RUNTIME.unwrap(NAMESPACE.get("gensym").app(RUNTIME.makeString("module")));
      rjs.config({ baseUrl: loaddir });

      var newRuntime = runtimeLib.makeRuntime({ 
        stdout: function(str) { process.stdout.write(str); },
        stderr: function(str) { process.stderr.write(str); },
      });

      RUNTIME.pauseStack(function(restarter) {
        newRuntime.runThunk(function() {
          newRuntime.safeCall(function() {
            return dialectsLib(newRuntime, newRuntime.namespace);
          }, function(dialects) {
            dialect = dialects.dialects[dialect];
            return newRuntime.safeCall(function() {
              return dialect.makeNamespace(newRuntime);
            }, function(newNamespace) {
              newRuntime.setParam("command-line-arguments", args);

              return newRuntime.loadModulesNew(newNamespace, [checkerLib], function(checkerLib) {
                var checker = newRuntime.getField(checkerLib, "values");
                var currentChecker = newRuntime.getField(checker, "make-check-context").app(newRuntime.makeString(modname), newRuntime.makeBoolean(checkAll));
                newRuntime.setParam("current-checker", currentChecker);

                function makeResult(execRt, callingRt, r) {
                  if(execRt.isSuccessResult(r)) {
                    var pyretResult = r.result;
                    return callingRt.makeObject({
                        "success": callingRt.makeBoolean(true),
                        "render-check-results": callingRt.makeFunction(function() {
                          var toCall = execRt.getField(checker, "render-check-results");
                          var checks = execRt.getField(pyretResult, "checks");
                          callingRt.pauseStack(function(restarter) {
                              execRt.run(function(rt, ns) {
                                  return toCall.app(checks);
                                }, execRt.namespace, {sync: true},
                                function(printedCheckResult) {
                                  if(execRt.isSuccessResult(printedCheckResult)) {
                                    if(execRt.isString(printedCheckResult.result)) {
                                      restarter.resume(callingRt.makeString(execRt.unwrap(printedCheckResult.result)));
                                    }
                                  }
                                  else if(execRt.isFailureResult(printedCheckResult)) {
                                    console.error(printedCheckResult);
                                    console.error(printedCheckResult.exn);
                                    restarter.resume(callingRt.makeString("There was an exception while formatting the check results"));
                                  }
                                });
                            });
                        })
                      });
                  }
                  else if(execRt.isFailureResult(r)) {
                    return callingRt.makeObject({
                        "success": callingRt.makeBoolean(false),
                        "failure": r.exn.exn,
                        "render-error-message": callingRt.makeFunction(function() {
                          callingRt.pauseStack(function(restarter) {
                            execRt.runThunk(function() {
                              if(execRt.isPyretVal(r.exn.exn)) {
                                return execRt.string_append(
                                  execRt.toReprJS(r.exn.exn, "_tostring"),
                                  execRt.makeString("\n" +
                                                    execRt.printPyretStack(r.exn.pyretStack)));
                              } else {
                                return String(r.exn + "\n" + r.exn.stack);
                              }
                            }, function(v) {
                              if(execRt.isSuccessResult(v)) {
                                return restarter.resume(v.result)
                              } else {
                                console.error("There was an exception while rendering the exception: ", r.exn, v.exn);
                              }
                            })
                          });
                        })
                      });
                  }
                }

                var loaded = loader.goodIdea(RUNTIME, name, str);
                loaded.fail(function(err) {
                  restarter.resume(makeResult(newRuntime, RUNTIME, newRuntime.makeFailureResult(err)));
                });

                loaded.then(function(moduleVal) {

                  /* run() starts the anonymous module's evaluation on a new stack
                     (created by newRuntime).  Once the evaluated program finishes
                     (if it ever does), the continuation is called with r as either
                     a Success or Failure Result from newRuntime. */

                  newRuntime.run(moduleVal, newNamespace, {sync: true}, function(r) {

                      /* makeResult handles turning values from the new runtime into values that
                         the calling runtime understands (since they don't share
                         the same instantiation of all the Pyret constructors like PObject, or the
                         same brands) */

                      var wrappedResult = makeResult(newRuntime, RUNTIME, r);

                      /* This restarts the calling stack with the new value, which
                         used constructors from the calling runtime.  From the point of view of the
                         caller, wrappedResult is the return value of the call to exec() */
                      restarter.resume(wrappedResult);
                  });
                });
              });
            }, "newRuntime making new namespace");
          }, "exec load dialectsLib");
        }, function(r) {
        })
      });

    };
    return RUNTIME.makeObject({
      provide: RUNTIME.makeObject({
        exec: RUNTIME.makeFunction(execWithDir)
      }),
      answer: NAMESPACE.get("nothing")
    });
  };
});

