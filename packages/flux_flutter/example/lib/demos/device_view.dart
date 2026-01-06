import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'code_preview.dart';

class DeviceView extends StatelessWidget {
  const DeviceView({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: This demo assumes Camera and BLE modules are registered in the runtime.
    const fluxSource = '''
      widget DeviceDemo {
        state cameraStatus = "Not Initialized";
        state imagePath = "";
        
        state bleStatus = "Idle";
        state bleDevices = [];
        state isScanning = false;

        build {
           ListView {
              Padding(padding: {"all": 10.0}, child: 
                 Text("Device Capabilities", style: {"fontSize": 24.0})
              );

              // Camera Section
              Container(
                 margin: {"all": 10.0},
                 padding: {"all": 10.0},
                 decoration: {
                    "border": {"all": {"color": "blue", "width": 1.0}},
                    "borderRadius": 8.0
                 },
                 child: Column {
                    Text("Camera Integration", style: {fontSize: 18.0, fontWeight: "bold"});
                    Text("Status: " + cameraStatus);
                    
                    if (imagePath != "") {
                       Text("Last Image: " + imagePath);
                       // Image(file: imagePath); // If Image widget supported file path
                    }
                    
                    SizedBox(height: 10.0);
                    
                    if (cameraStatus == "Not Initialized") {
                       Button("Initialize Camera", onPressed: fn() {
                          cameraStatus = "Initializing...";
                          var res = await camera.initialize({
                             "cameraId": 0,
                             "resolution": "medium"
                          });
                          
                          if (res["success"]) {
                             cameraStatus = "Ready (Res: " + res["resolution"] + ")";
                          } else {
                             cameraStatus = "Error: " + res["error"];
                          }
                       });
                    } else {
                       SizedBox(
                          height: 300.0,
                          child: CameraPreview() 
                       );
                       
                       Row {
                          Button("Take Picture", onPressed: fn() {
                             var res = await camera.takePicture();
                             if (res["success"]) {
                                imagePath = res["path"];
                                cameraStatus = "Captured: " + res["name"];
                             } else {
                                cameraStatus = "Capture Error: " + res["error"];
                             }
                          });
                          
                          SizedBox(width: 10.0);
                          
                          Button("Dispose", onPressed: fn() {
                              await camera.dispose();
                              cameraStatus = "Not Initialized";
                          });
                       }
                    }
                 }
              );
              
              
              // BLE Section
              Container(
                 margin: {"all": 10.0},
                 padding: {"all": 10.0},
                 decoration: {
                    "border": {"all": {"color": "green", "width": 1.0}},
                    "borderRadius": 8.0
                 },
                 child: Column {
                    Text("Bluetooth Low Energy", style: {"fontSize": 18.0, "fontWeight": "bold"});
                    Text("Status: " + bleStatus);
                    
                    SizedBox(height: 10.0);
                    
                    Button(isScanning ? "Scanning..." : "Start Scan (2s)", onPressed: fn() {
                       if (isScanning) return;
                       
                       isScanning = true;
                       bleStatus = "Scanning...";
                       bleDevices = [];
                       
                       // Scan for 2 seconds
                       await ble.startScan({"timeout": 2000});
                       
                       // Get results
                       var devs = ble.getDiscoveredDevices();
                       bleDevices = devs;
                       
                       bleStatus = "Found " + devs.length.toString() + " devices";
                       isScanning = false;
                    });
                    
                    Text("Devices Found: ");
                    
                    // List discovered devices
                    // Map over bleDevices list
                    ListView(
                       shrinkWrap: true,
                       physics: "NeverScrollableScrollPhysics", // Not supported directly in Flux string map implies... use Column loop
                       children: bleDevices.map(fn(d) {
                          return Container(
                             margin: {"bottom": 5.0},
                             padding: {"all": 5.0},
                             color: "#EEEEEE",
                             child: Column {
                                Text(d["id"], style: {"fontWeight": "bold"});
                                Text("RSSI: " + d["rssi"].toString());
                             }
                          );
                       })
                    );
                 }
              );
           }
        }
      }
    ''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CodePreviewScreen(
                    title: 'Device',
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
        widgetName: 'DeviceDemo',
      ),
    );
  }
}
