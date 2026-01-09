/// Memory management and tracking for Flux VM
class MemoryStats {
  int aliveInstances = 0;
  int aliveClosures = 0;
  int aliveUpvalues = 0;
  int totalAllocated = 0;

  Map<String, dynamic> toJson() => {
    'aliveInstances': aliveInstances,
    'aliveClosures': aliveClosures,
    'aliveUpvalues': aliveUpvalues,
    'totalAllocated': totalAllocated,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
}

class MemoryManager {
  final MemoryStats _stats = MemoryStats();

  MemoryStats get stats => _stats;

  void recordAllocation(Object obj) {
    _stats.totalAllocated++;
    // In a real GC'd language like Dart, we can't easily track "deallocation" 
    // without using Finalizer (Dart 2.17+).
    // We will use Finalizer to track true "alive" count if supported by the environment.
  }

  // Finalizer for tracking GC'd objects
  late final Finalizer<String> _finalizer = Finalizer<String>((type) {
    switch (type) {
      case 'instance':
        _stats.aliveInstances--;
        break;
      case 'closure':
        _stats.aliveClosures--;
        break;
      case 'upvalue':
        _stats.aliveUpvalues--;
        break;
    }
  });

  void trackInstance(Object instance) {
    _stats.aliveInstances++;
    _stats.totalAllocated++;
    _finalizer.attach(instance, 'instance');
  }

  void trackClosure(Object closure) {
    _stats.aliveClosures++;
    _stats.totalAllocated++;
    _finalizer.attach(closure, 'closure');
  }

  void trackUpvalue(Object upvalue) {
    _stats.aliveUpvalues++;
    _stats.totalAllocated++;
    _finalizer.attach(upvalue, 'upvalue');
  }
}
