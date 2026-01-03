/// Widget Catalog for LSP Completion
/// 
/// Provides property information for all supported Flutter widgets
class WidgetCatalog {
  static final Map<String, List<PropertyInfo>> catalog = {
    // Layout Widgets
    'Container': [
      PropertyInfo('child', 'Widget', 'The child widget'),
      PropertyInfo('width', 'double', 'Width of the container'),
      PropertyInfo('height', 'double', 'Height of the container'),
      PropertyInfo('color', 'Color', 'Background color'),
      PropertyInfo('padding', 'EdgeInsets', 'Inner padding'),
      PropertyInfo('margin', 'EdgeInsets', 'Outer margin'),
      PropertyInfo('decoration', 'BoxDecoration', 'Container decoration'),
      PropertyInfo('alignment', 'Alignment', 'Child alignment'),
    ],
    'Column': [
      PropertyInfo('children', 'List<Widget>', 'Child widgets'),
      PropertyInfo('mainAxisAlignment', 'MainAxisAlignment', 'Vertical alignment'),
      PropertyInfo('crossAxisAlignment', 'CrossAxisAlignment', 'Horizontal alignment'),
      PropertyInfo('mainAxisSize', 'MainAxisSize', 'How much space to occupy'),
    ],
    'Row': [
      PropertyInfo('children', 'List<Widget>', 'Child widgets'),
      PropertyInfo('mainAxisAlignment', 'MainAxisAlignment', 'Horizontal alignment'),
      PropertyInfo('crossAxisAlignment', 'CrossAxisAlignment', 'Vertical alignment'),
      PropertyInfo('mainAxisSize', 'MainAxisSize', 'How much space to occupy'),
    ],
    'Stack': [
      PropertyInfo('children', 'List<Widget>', 'Child widgets'),
      PropertyInfo('alignment', 'AlignmentGeometry', 'Non-positioned children alignment'),
      PropertyInfo('fit', 'StackFit', 'How to size non-positioned children'),
    ],
    'Positioned': [
      PropertyInfo('child', 'Widget', 'The child widget'),
      PropertyInfo('left', 'double', 'Distance from left'),
      PropertyInfo('top', 'double', 'Distance from top'),
      PropertyInfo('right', 'double', 'Distance from right'),
      PropertyInfo('bottom', 'double', 'Distance from bottom'),
      PropertyInfo('width', 'double', 'Fixed width'),
      PropertyInfo('height', 'double', 'Fixed height'),
    ],
    'Center': [
      PropertyInfo('child', 'Widget', 'The child widget'),
      PropertyInfo('widthFactor', 'double', 'Width factor'),
      PropertyInfo('heightFactor', 'double', 'Height factor'),
    ],
    'Padding': [
      PropertyInfo('child', 'Widget', 'The child widget'),
      PropertyInfo('padding', 'EdgeInsets', 'The padding amount'),
    ],
    'SizedBox': [
      PropertyInfo('child', 'Widget', 'The child widget'),
      PropertyInfo('width', 'double', 'Fixed width'),
      PropertyInfo('height', 'double', 'Fixed height'),
    ],
    'Expanded': [
      PropertyInfo('child', 'Widget', 'The child widget'),
      PropertyInfo('flex', 'int', 'Flex factor'),
    ],
    
    // Text & Input Widgets
    'Text': [
      PropertyInfo('data', 'String', 'The text to display (positional)'),
      PropertyInfo('style', 'TextStyle', 'Text styling'),
      PropertyInfo('textAlign', 'TextAlign', 'Text alignment'),
      PropertyInfo('maxLines', 'int', 'Maximum number of lines'),
      PropertyInfo('overflow', 'TextOverflow', 'Overflow handling'),
    ],
    'TextField': [
      PropertyInfo('controller', 'TextEditingController', 'Text controller'),
      PropertyInfo('decoration', 'InputDecoration', 'Input decoration'),
      PropertyInfo('onChanged', 'Function(String)', 'Value change callback'),
      PropertyInfo('onSubmitted', 'Function(String)', 'Submit callback'),
      PropertyInfo('keyboardType', 'TextInputType', 'Keyboard type'),
      PropertyInfo('obscureText', 'bool', 'Hide text (password)'),
      PropertyInfo('maxLines', 'int', 'Maximum lines'),
    ],
    
    // Button Widgets
    'ElevatedButton': [
      PropertyInfo('child', 'Widget', 'Button content'),
      PropertyInfo('onPressed', 'Function', 'Press callback'),
      PropertyInfo('style', 'ButtonStyle', 'Button styling'),
    ],
    'TextButton': [
      PropertyInfo('child', 'Widget', 'Button content'),
      PropertyInfo('onPressed', 'Function', 'Press callback'),
      PropertyInfo('style', 'ButtonStyle', 'Button styling'),
    ],
    'OutlinedButton': [
      PropertyInfo('child', 'Widget', 'Button content'),
      PropertyInfo('onPressed', 'Function', 'Press callback'),
      PropertyInfo('style', 'ButtonStyle', 'Button styling'),
    ],
    'IconButton': [
      PropertyInfo('icon', 'Widget', 'Button icon'),
      PropertyInfo('onPressed', 'Function', 'Press callback'),
      PropertyInfo('iconSize', 'double', 'Icon size'),
      PropertyInfo('color', 'Color', 'Icon color'),
    ],
    
    // List Widgets
    'ListView': [
      PropertyInfo('children', 'List<Widget>', 'Child widgets'),
      PropertyInfo('padding', 'EdgeInsets', 'List padding'),
      PropertyInfo('scrollDirection', 'Axis', 'Scroll direction'),
      PropertyInfo('shrinkWrap', 'bool', 'Shrink to content size'),
    ],
    'ListTile': [
      PropertyInfo('title', 'Widget', 'Primary content'),
      PropertyInfo('subtitle', 'Widget', 'Secondary content'),
      PropertyInfo('leading', 'Widget', 'Leading widget'),
      PropertyInfo('trailing', 'Widget', 'Trailing widget'),
      PropertyInfo('onTap', 'Function', 'Tap callback'),
    ],
    
    // Scaffold & Navigation
    'Scaffold': [
      PropertyInfo('appBar', 'PreferredSizeWidget', 'Top app bar'),
      PropertyInfo('body', 'Widget', 'Main content'),
      PropertyInfo('floatingActionButton', 'Widget', 'FAB'),
      PropertyInfo('drawer', 'Widget', 'Side drawer'),
      PropertyInfo('bottomNavigationBar', 'Widget', 'Bottom nav'),
    ],
    'AppBar': [
      PropertyInfo('title', 'Widget', 'Title widget'),
      PropertyInfo('leading', 'Widget', 'Leading widget'),
      PropertyInfo('actions', 'List<Widget>', 'Action widgets'),
      PropertyInfo('backgroundColor', 'Color', 'Background color'),
    ],
    
    // Media & Icons
    'Icon': [
      PropertyInfo('icon', 'IconData', 'Icon data (positional)'),
      PropertyInfo('size', 'double', 'Icon size'),
      PropertyInfo('color', 'Color', 'Icon color'),
    ],
    'Image': [
      PropertyInfo('src', 'String', 'Image source URL'),
      PropertyInfo('width', 'double', 'Image width'),
      PropertyInfo('height', 'double', 'Image height'),
      PropertyInfo('fit', 'BoxFit', 'Image fit'),
    ],
    
    // Card & Decoration
    'Card': [
      PropertyInfo('child', 'Widget', 'Card content'),
      PropertyInfo('elevation', 'double', 'Shadow elevation'),
      PropertyInfo('color', 'Color', 'Background color'),
      PropertyInfo('margin', 'EdgeInsets', 'Card margin'),
    ],
    
    // Interaction
    'GestureDetector': [
      PropertyInfo('child', 'Widget', 'The child widget'),
      PropertyInfo('onTap', 'Function', 'Tap callback'),
      PropertyInfo('onDoubleTap', 'Function', 'Double tap callback'),
      PropertyInfo('onLongPress', 'Function', 'Long press callback'),
    ],
    'InkWell': [
      PropertyInfo('child', 'Widget', 'The child widget'),
      PropertyInfo('onTap', 'Function', 'Tap callback'),
      PropertyInfo('splashColor', 'Color', 'Ripple color'),
    ],
  };
  
  /// Get properties for a widget
  static List<PropertyInfo>? getProperties(String widgetName) {
    return catalog[widgetName];
  }
  
  /// Get all widget names
  static List<String> get widgetNames => catalog.keys.toList();
}

/// Information about a widget property
class PropertyInfo {
  final String name;
  final String type;
  final String description;
  
  const PropertyInfo(this.name, this.type, this.description);
  
  Map<String, dynamic> toCompletionItem() => {
    'label': name,
    'kind': 10, // Property
    'detail': type,
    'documentation': description,
    'insertText': '$name: ',
  };
}
