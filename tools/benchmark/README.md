### Setup

Note: all commands assume a current working directory of `<repo>/tools/benchmark`. Also, before using, ensure phase1 is built.

Benchmark tool uses [benchmark.js v1.0.0](http://benchmarkjs.com/) to measure Pyret performance, which in turn also depends on platform.js and lodash.js. These should be set up when installing Pyret, as they are listed as dependencies.

One run the tests of these benchmarking tools from the tools/benchmark directory via `node tests` to make sure nothing is broken, but these are also run when running `make test` when setting up Pyret, so one can also just not worry about it.

### Profile a Pyret Program

To measure the performance of (a) Pyret program(s) from a file, simply run

`node measure-program <filename0> <filename1> ... <filename_n>`

#### Programmatic Options
To measure the performance of programs which are Javascript strings, it may be easiest to copy examples.js and examples-code.js, editing the latter, then running examples.js in node.

For an example of something with options passed into the evaluator, check out type-check-compare.js and type-check-compare-code.js (run the former in node).

### What's Going On?

At the moment, we are measuring parsing (source -> ast), loading (ast -> js), and evaluating (js -> result) programs with eval-lib.js.

When a program is benchmarked, you'll see something like this:

```
CURRENT BENCHMARK: longmap2.arr  
Ensuring program runs successfully...  
...done.  
parse x 127 ops/sec +/- 6.48% (72 runs sampled)  
load x 2.38 ops/sec +/- 1.25% (16 runs sampled)  
eval_loaded x 39.38 ops/sec +/- 184.01% (33 runs sampled)  
Fastest is parse  
Slowest is load
```  

(This was from measuring the program 'range(0,10000).map(lam(x): x + 1 end)')

The number immediately preceding 'ops/sec' is the main thing to focus on. The higher this number, the faster that function ran. In order to be as accurate, benchmark.js runs the given function as many times as it can within some elapsed time, measuring each run indivudually. Then it samples some subset of the measurements and gives back a mean with a percentage uncertainty. For information, see this StackOverflow post: [http://stackoverflow.com/a/4996963](http://stackoverflow.com/a/4996963)

### Auto Report
At the moment, one can run `node auto-report` to profile all the programs in the directory `auto-report-programs`. At the moment, data just spits out to the console. The goal of the near future is to adapt this into something that is *actually* automatic.
