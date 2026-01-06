import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'code_preview.dart';

class UIView extends StatelessWidget {
  const UIView({super.key});

  @override
  Widget build(BuildContext context) {
    const fluxSource = '''
      widget UIDemo {
        state counter = 0;
        state textVal = "";

        build {
          ListView {
            Padding(padding: {"all": 10.0}, child: 
               Text("UI Component Gallery", style: {"fontSize": 24.0})
            );

            // Card Style Container
            Container(
              margin: {"all": 10.0},
              padding: {"all": 15.0},
              decoration: {
                "color": 0xFFE3F2FD, // Colors.blue[50]
                "borderRadius": 10.0
              },
              child: Column {
                 Text("Interactive Components", style: {"fontWeight": "bold"});
                 SizedBox(height: 10.0);
                 
                 Row {
                    Text("Counter: " + counter.toString());
                    SizedBox(width: 20.0);
                    Button("+", onPressed: fn() {
                      counter = counter + 1;
                    });
                     Button("-", onPressed: fn() {
                      counter = counter - 1;
                    });
                 }
              }
            );

            // Input Section
             Container(
              margin: {"all": 10.0},
              padding: {"all": 15.0},
              decoration: {
                 "border": {"all": {"color": "grey", "width": 1.0}},
                 "borderRadius": 10.0
              },
              child: Column {
                 Text("Text Input", style: {"fontWeight": "bold"});
                 Input(
                    value: textVal,
                    onChanged: fn(val) {
                       textVal = val;
                    },
                    decoration: {
                      "labelText": "Type something...",
                      "border": "outline"
                    }
                 );
                 Text("You typed: " + textVal);
              }
            );
            
            // Layout alignment
            Container(
               margin: {"all": 10.0},
               height: 100.0,
               color: 0xFFFFF3E0, // Orange[50]
               child: Center {
                  Text("Centered Content")
               }
            );

            // Stack
            Container(
               margin: {"all": 10.0},
               height: 100.0,
               color: 0xFFF3E5F5, // Purple[50]
               child: Stack(
                 children: [
                    Positioned(
                       top: 10.0,
                       left: 10.0,
                       child: Text("Top Left")
                    ),
                     Positioned(
                       bottom: 10.0,
                       right: 10.0,
                       child: Text("Bottom Right")
                    ),
                    Center(child: Text("Stack Demo"))
                 ]
               )
            );
          }
        }
      }
    ''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('UI Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CodePreviewScreen(
                    title: 'UI Components',
                    source: fluxSource,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FluxWidget(
        source: fluxSource,
        widgetName: 'UIDemo',
      ),
    );
  }
}
