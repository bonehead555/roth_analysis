  import 'package:path/path.dart' as p;
  
  /// Extracts/Returns the base path and its extension from the provided [filePath].
  /// Handles cases where there are mutiple possible extensions
  /// e.g., "name.roth", "name.roth."
  /// Choses the extension first specified, e.g., ".roth"
  /// Chosen as FilePicker.platform.saveFile does odd stuff when an extension is specified with more than 4 characters.
  (String basePath, String pathExtension) getBasePathAndExtension(
      String filePath) {
    String basePath = filePath;
    String pathExtension = '';
    String extensionNext = p.extension(basePath);
    while (extensionNext != '') {
      pathExtension = extensionNext;
      basePath = p.setExtension(basePath, '');
      extensionNext = p.extension(basePath);
    }
    return (basePath, pathExtension);
  }