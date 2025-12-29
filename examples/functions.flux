// Recursive function test in Flux

fn fib(n) {
    if (n < 2) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

print(fib(5));   // Should print 5
print(fib(10));  // Should print 55
