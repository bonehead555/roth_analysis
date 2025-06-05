import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roth_analysis/providers/analysis_provider.dart';
import 'package:roth_analysis/screens/home/help_view.dart';
import 'package:roth_analysis/screens/home/load_providers.dart';
import 'package:roth_analysis/screens/home/save_providers.dart';
import 'package:roth_analysis/utilities/get_base_path_and_extension.dart';
import 'package:roth_analysis/services/message_service.dart';
import 'package:roth_analysis/widgets/configuration/configuration.dart';
import 'package:roth_analysis/widgets/graph_view/graph_view.dart';
import 'package:roth_analysis/widgets/table_view/table_view.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:roth_analysis/widgets/app_bar_controller.dart';
import 'package:path/path.dart' as p;
import 'package:roth_analysis/widgets/utility/app_bar_divider.dart';

import '../../widgets/transaction_view/transaction_view.dart';
import 'messages_view.dart';

/// Manages the list ofnavigation options in the NavigationRail widget.
/// * [label] - Label to use for a given item in the navigation rail.
/// * [icon] - ICON to use for item in the navigation rail.
/// * [selectedIcon] - ICON to use item in the navigation rail when is selected.
/// * [appBarController] - App bar controller to use when item in the navigation rail is selected.
/// * [childScreen] - Child screen to be shown when item in navigation rail is selected.
class NavOption {
  const NavOption(
    this.label,
    this.icon,
    this.selectedIcon,
    this.screenPath,
    this.appBarController,
    this.childScreen,
  );

  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final String screenPath;
  final AppBarController appBarController;
  final Widget childScreen;
}

/// HOME screen for the application.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String openFilePath = '';
  int _selectedIndex = 0;
  late List<NavOption> _destinations;
  final int _configurationIndex = 0;
  String appBarTitle = '';
  List<Widget> actionAdditions = [];

  @override
  void initState() {
    // Create an app bar controller to use for each of the possible navigation items
    AppBarController configAppBarController =
        AppBarController(onUpdated: onUpdatedAppBarInfo);
    AppBarController tableViewAppBarController =
        AppBarController(onUpdated: onUpdatedAppBarInfo);
    AppBarController graphViewAppBarController =
        AppBarController(onUpdated: onUpdatedAppBarInfo);
    AppBarController transactionViewAppBarController =
        AppBarController(onUpdated: onUpdatedAppBarInfo);

    // Create a list of NavOption, one for each possible navigation options.
    _destinations = <NavOption>[
      NavOption(
        // This option muct come first.
        '',
        const Tooltip(
            message: 'Configuration', child: Icon(Icons.settings_outlined)),
        const Tooltip(message: 'Configuration', child: Icon(Icons.settings)),
        '/configuration',
        configAppBarController,
        Configuration(appBarController: configAppBarController),
      ),
      NavOption(
        '',
        const Tooltip(
            message: 'Table View', child: Icon(Icons.grid_view_outlined)),
        const Tooltip(message: 'Table View', child: Icon(Icons.grid_view)),
        '/table_view',
        tableViewAppBarController,
        TableView(appBarController: tableViewAppBarController),
      ),
      NavOption(
        '',
        const Tooltip(
            message: 'Graph View', child: Icon(Icons.show_chart_outlined)),
        const Tooltip(message: 'Graph View', child: Icon(Icons.show_chart)),
        '/graph_view',
        graphViewAppBarController,
        GraphView(appBarController: graphViewAppBarController),
      ),
      NavOption(
        '',
        const Tooltip(
            message: 'Transaction Log',
            child: Icon(Icons.manage_history_outlined)),
        const Tooltip(
            message: 'Transaction Log', child: Icon(Icons.manage_history)),
        '/transaction_view',
        transactionViewAppBarController,
        TransactionView(appBarController: transactionViewAppBarController),
      ),
    ];

    super.initState();
  }

  /// Updates state information when a new navigation item is selected.
  void onUpdatedAppBarInfo() {
    setState(() {
      appBarTitle = _destinations[_selectedIndex].appBarController.title;
      actionAdditions =
          _destinations[_selectedIndex].appBarController.actionAdditions;
    });
  }

  /// Handles loading a saved configuration file. I.e.,
  /// * Launches appropirate file picker.
  /// * Invokes file load and parsing function.
  /// * Launches error dialog if needed.
  void fileOpen() async {
    // Ask for file location to load configuration
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select Roth Configuration File',
      initialDirectory: appDocumentsDir.path,
      type: FileType.custom,
      allowedExtensions: ['roth'],
    );
    // exit if no file was specified.
    if (result == null) return;
    String? tempFilePath = result.files.single.path;
    if (tempFilePath == null || tempFilePath == '') return;

    // Get filePath parts and update flilePath to use proper extension
    String filePath = tempFilePath;
    var (basePath, extension) = getBasePathAndExtension(filePath);
    filePath = p.setExtension(basePath, '.roth');

    String statusMessage = 'Configuration successfully loaded from: $filePath';
    // Check if valid extension was specified.
    if (extension != '.roth' && extension != '') {
      statusMessage = 'Invalid file extension ("$extension")';
    }
    // file specification if good to continue
    else {
      // Load the provider information from specified file.
      MessageService messageService = MessageService();
      await loadProviders(ref, filePath, messageService);

      // Update status message
      if (messageService.counts != 0) {
        await _messagesDialog(
            header: 'Resolve "Errors" to Proceed Loading Configuration File',
            messageService: messageService);
        statusMessage =
            'Configuration failed to load from: $filePath. ${messageService.counts} errors encountered';
      }

      if (messageService.errorCount == 0) {
        openFilePath = filePath;
        _switchScreens(_configurationIndex);
      }
    }

    final snackBar = SnackBar(
      content: Text(statusMessage),
      duration: const Duration(milliseconds: 1500),
    );
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void fileSave() {
    if (openFilePath.isEmpty) {
      fileSaveAs();
    } else {
      fileSaveWorker(openFilePath);
    }
  }

  /// Handles saving to a configuration file. I.e.,
  /// * Launches appropirate file picker.
  /// * Invokes file save function.
  void fileSaveAs() async {
    // Ask for file location to save configuration
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    String? filePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Select Roth Configuration File to Save',
      initialDirectory: appDocumentsDir.path,
      type: FileType.custom,
      allowedExtensions: ['roth'],
    );
    // exit if no file was specified.
    if (filePath == null || filePath == '') return;

    // Call the file save worker method, then
    // check if file successfully saved and if so, update the open file path.
    if (await fileSaveWorker(filePath)) {
      openFilePath = filePath;
    }
  }

  /// Save the configuration to the file specified in [filePath].
  /// Returns true of configuration was successfully saved.
  Future<bool> fileSaveWorker(String filePath) async {
    bool fileSaved = false;
    // Get filePath parts and update fliePath to use proper extension
    var (basePath, extension) = getBasePathAndExtension(filePath);
    filePath = p.setExtension(basePath, '.roth');

    String statusMessage =
        'Unknown error attempting to save configuration to: $filePath';

    // Check if valid extension was specified.
    if (extension != '.roth' && extension != '') {
      statusMessage = 'Invalid file extension ("$extension")';
      // file specification if good to continue
    } else {
      // Save the provider information to specified file.
      MessageService messageService = MessageService();
      await saveProviders(ref, filePath, messageService);

      // Update status message
      if (messageService.counts != 0) {
        statusMessage =
            'Configuration failed to saved to: $filePath. ${messageService.counts} errors encountered';
      } else {
        statusMessage = 'Configuration successfully saved to: $filePath';
        fileSaved = true;
      }
    }

    // Display status message in a SnackBar
    final snackBar = SnackBar(
      content: Text(statusMessage),
      duration: const Duration(milliseconds: 1500),
      // ignore: use_build_context_synchronously
      backgroundColor: Theme.of(context).colorScheme.secondary,
    );
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    return fileSaved;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          appBarTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        actions: [
          // Add in any AppBar widgets added by the selected item in the navigation bar.
          if (actionAdditions.isNotEmpty) const AppBarDivider(),
          if (actionAdditions.isNotEmpty) ...actionAdditions,
          // Add our own AppBar widgets
          const AppBarDivider(),
          Tooltip(
            message: 'Open',
            child: IconButton(
              onPressed: fileOpen,
              icon: const Icon(Icons.file_open),
            ),
          ),
          Tooltip(
            message: 'Save',
            child: IconButton(
              onPressed: fileSave,
              icon: const Icon(Icons.save),
            ),
          ),
          Tooltip(
            message: 'Save-As',
            child: IconButton(
              onPressed: fileSaveAs,
              icon: const Icon(Icons.save_as),
            ),
          ),
          Tooltip(
            message: 'Help',
            child: IconButton(
              onPressed: () {_helpDialog(appBarTitle);},
              icon: const Icon(Icons.help),
            ),
          ),
        ],
      ),
      body: Row(
        // Consists of the NavigationRail on the right, a divider, and the child/extenstions on the left.
        children: <Widget>[
          NavigationRail(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            selectedIndex: _selectedIndex,
            groupAlignment: -1.0,
            onDestinationSelected: (int index) async {
              // Deternmine if configuration was changed since we were last here.
              // And establish a baseline for analysis configuration state.
              final bool configHasChanged = ref.read(configChangedProvider);
              AnalysisConfigState analysisConfigState =
                  ref.read(analysisProvider);
              // If NOT attempting to enter the configuration sceen, and
              // the configuration is changed, try to validate / analyze the new configuration.
              if (index != 0 && configHasChanged) {
                analysisConfigState = ref
                    .read(analysisProvider.notifier)
                    .validateConfiguration(ref);
              }
              // If NOT attempting to enter the configuration sceen, and
              // the configuration is still valid, display the configuration errors.
              if (index != 0 && analysisConfigState.configErrors.counts != 0) {
                await _messagesDialog(
                    header: 'Resolve Configuration Errors to Proceed.',
                    messageService: analysisConfigState.configErrors);
              }
              // If either attempting to enter the configuration screen, or
              // the configuration is now valid, swicth screens.
              // Stated differently, lets not switch screens if configuration is NOT valid,
              // unless were entering the configuration sceen itself.
              if (index == 0 || analysisConfigState.planResults != null) {
                _switchScreens(index);
              }
              //Navigator.pushReplacementNamed(context, destinations[index].screenPath);
            },
            labelType: NavigationRailLabelType.all,
            destinations: _destinations.map(
              (NavOption destination) {
                return NavigationRailDestination(
                  label: Text(destination.label),
                  icon: destination.icon,
                );
              },
            ).toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                for (final NavOption option in _destinations) option.childScreen
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _switchScreens(int newScreenIndex) {
    setState(() {
      _selectedIndex = newScreenIndex;
      appBarTitle = _destinations[_selectedIndex].appBarController.title;
      actionAdditions =
          _destinations[_selectedIndex].appBarController.actionAdditions;
    });
  }

  /// Dialog that displays any errors discovered in any process that uses a [MessageService].
  /// * [header] - Header text to be displayed at the top of the dialog.
  /// * [messageService] - COntains any errors/warnings/info that should be displayed.
  Future _messagesDialog(
      {required String header, required MessageService messageService}) async {
    double navRailWidth = 82;
    double gap = 40;
    double leftOffset = navRailWidth + gap;
    double rightOffset = context.size!.width - leftOffset;
    //double dialogHeight = context.size!.height * 0.9;
    double dialogWidth = rightOffset - leftOffset;
    Offset parentOffset =
        (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero);
    double dialogX = parentOffset.dx + leftOffset;
    double dialogY = parentOffset.dy + 100;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => Dialog(
        alignment: Alignment.topLeft,
        insetPadding: EdgeInsets.only(top: dialogY, left: dialogX),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        child: MessagesView(
          header: header,
          messageService: messageService,
          width: dialogWidth,
        ),
      ),
    );
    return;
  }

  /// Dialog that displays application help information.
  /// * [toBookmark] - Bookmark / Heading show.
  Future _helpDialog(String? toBookmark) async {
    double navRailWidth = 82;
    double gap = 20;
    double leftOffset = navRailWidth + gap;
    Offset parentOffset =
        (context.findRenderObject()! as RenderBox).localToGlobal(Offset.zero);
    double dialogX = parentOffset.dx + leftOffset;
    double dialogY = parentOffset.dy + 80;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => Dialog(
        alignment: Alignment.topLeft,
        insetPadding: EdgeInsets.only(top: dialogY, left: dialogX),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
        child: HelpView(toBookmark: toBookmark),
      ),
    );
    return;
  }
}
