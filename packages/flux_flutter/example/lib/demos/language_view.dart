import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';

class LanguageView extends StatelessWidget {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    const fluxSource = '''
      widget LanguageDemo {
        state result = "Ready to run.";
        state execTime = "0ms";

        build {
          Column {
            Text("Flux Language Benchmarks", style: {"fontSize": 20.0, "fontWeight": "bold"});
            
            Padding(padding: {"top": 20.0, "bottom": 10.0}, child: 
              Text("Result: " + result)
            );
            
            Text("Execution Time: " + execTime, style: {"color": "grey"});

            SizedBox(height: 20.0);

            Button("Run Fibonacci (recursive)", onPressed: fn() {
               var start = DateTime.now();
               
               // Recursive Fib function
               var fib = fn(n) {
                 if (n <= 1) return n;
                 return fib(n - 1) + fib(n - 2);
               };
               
               var res = fib(25); 
               
               var end = DateTime.now();
               result = "Fib(25) = " + res.toString();
               execTime = (end - start) + "ms";
            });

            Button("String Operations", onPressed: fn() {
               var start = DateTime.now();
               
               var s = "";
               for (var i = 0; i < 1000; i = i + 1) {
                 s = s + ".";
               }
               
               var end = DateTime.now();
               result = "Concatenated 1000 dots";
               execTime = (end - start) + "ms";
            });
            
             Button("List & Map", onPressed: fn() {
               var start = DateTime.now();
               
               var list = [];
               for (var i = 0; i < 100; i = i + 1) {
                 list.add(i);
               }
               
               var map = {};
               map["sum"] = 0;
               
               for (var i = 0; i < list.length; i = i + 1) {
                  map["sum"] = map["sum"] + list[i];
               }
               
               var end = DateTime.now();
               result = "Validating List Sum (0..99): " + map["sum"];
               execTime = (end - start) + "ms";
            });
          }
        }
      }
    ''';

    return Scaffold(
      appBar: AppBar(title: const Text('Language Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FluxWidget(
          source: fluxSource,
          widgetName: 'LanguageDemo',
        ),
      ),
    );
  }
}
