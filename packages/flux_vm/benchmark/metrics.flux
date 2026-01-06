class Runner {
  fn fib(n) {
    if (n < 2) return n;
    return this.fib(n - 1) + this.fib(n - 2);
  }
}

var runner = Runner();
var start = clock();
var result = runner.fib(20);
var end = clock();

print("Fib(20) = " + result);
