import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:html' as html; // Used for downloading CSV file in web
import '../../../../config/theme.config.dart';
import '../../../../controllers/leads/leads.controller.dart';
import '../../../../models/staff.model.dart';

class ImportWizard extends StatefulWidget {
  final String importId;
  final List<String> sheetNames;
  final List<dynamic> columnPreview;
  final List<dynamic> previewRows;
  final Map<String, dynamic> suggestedMapping;

  const ImportWizard({
    super.key,
    required this.importId,
    required this.sheetNames,
    required this.columnPreview,
    required this.previewRows,
    required this.suggestedMapping,
  });

  @override
  State<ImportWizard> createState() => _ImportWizardState();
}

class _ImportWizardState extends State<ImportWizard> {
  final _leadsController = Get.find<LeadsController>();
  
  int _currentStep = 1; // 1 = Sheet/Mapping, 2 = Options/Preview, 3 = Progress/Summary
  bool _isProcessing = false;
  bool _loadingPreview = false;
  
  // Sheet & Mapping State
  late String _selectedSheet;
  final Map<String, int> _fieldMappings = {}; // CRM Field Key -> Excel Column Index
  final Map<String, TextEditingController> _numInputControllers = {};
  
  // Custom templates
  List<dynamic> _templates = [];
  String? _selectedTemplateId;
  
  // Options State
  String _duplicateStrategy = 'skip';
  String? _assignedRM;
  String _leadStage = 'New';

  // Lead Pools State
  List<dynamic> _leadPools = [];
  String? _selectedLeadPoolId;
  final _newPoolNameCtrl = TextEditingController();
  final _newPoolDescCtrl = TextEditingController();
  
  // Template Save State
  bool _saveAsTemplate = false;
  final _templateNameCtrl = TextEditingController();

  // Field definitions retrieved dynamically
  List<dynamic> _crmFields = [];
  bool _loadingFields = true;

  // Validation Preview Rows
  List<dynamic> _previewValidationRows = [];

  // Progress state
  int _totalRows = 0;
  int _processedRows = 0;
  int _successfulRows = 0;
  int _failedRows = 0;
  int _duplicateRows = 0;
  String _jobStatus = 'mapping_required';
  List<dynamic> _errorLogs = [];
  
  @override
  void initState() {
    super.initState();
    _selectedSheet = widget.sheetNames.first;
    _fetchCrmFields();
    _fetchTemplates();
    _fetchLeadPools();
    _applySuggestions();
  }

  void _applySuggestions() {
    widget.suggestedMapping.forEach((fieldKey, data) {
      final colIdx = data['columnIndex'] as int;
      _fieldMappings[fieldKey] = colIdx;
    });
  }

  Future<void> _fetchLeadPools() async {
    final res = await _leadsController.leadService.getLeadPools();
    if (!res.status.hasError && res.body != null) {
      setState(() {
        _leadPools = res.body['data'] as List? ?? [];
        if (_selectedLeadPoolId == null && _leadPools.isNotEmpty) {
          final freshPool = _leadPools.firstWhere(
            (p) => p['name'] == 'Fresh Leads',
            orElse: () => null,
          );
          if (freshPool != null) {
            _selectedLeadPoolId = freshPool['_id']?.toString();
          }
        }
      });
    }
  }

  Future<void> _createNewLeadPoolDialog() async {
    _newPoolNameCtrl.clear();
    _newPoolDescCtrl.clear();
    
    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create New Lead Pool', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _newPoolNameCtrl,
                decoration: const InputDecoration(labelText: 'Pool Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPoolDescCtrl,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_newPoolNameCtrl.text.isNotEmpty) {
                        final res = await _leadsController.leadService.createLeadPool(
                          _newPoolNameCtrl.text,
                          _newPoolDescCtrl.text.isEmpty ? null : _newPoolDescCtrl.text,
                        );
                        if (!res.status.hasError && res.body != null) {
                          await _fetchLeadPools();
                          setState(() {
                            _selectedLeadPoolId = res.body['data']['_id'].toString();
                          });
                          Get.back();
                        } else {
                          Get.snackbar('Error', 'Failed to create pool: ${res.body?['message'] ?? ''}');
                        }
                      }
                    },
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchCrmFields() async {
    setState(() => _loadingFields = true);
    final res = await _leadsController.leadService.getImportFields();
    if (!res.status.hasError && res.body != null) {
      _crmFields = res.body['data'] as List? ?? [];
      for (final f in _crmFields) {
        final key = f['key'] as String;
        _numInputControllers[key] = TextEditingController(
          text: _fieldMappings[key]?.toString() ?? '',
        );
      }
    }
    setState(() => _loadingFields = false);
  }

  Future<void> _fetchTemplates() async {
    final res = await _leadsController.leadService.getTemplates();
    if (!res.status.hasError && res.body != null) {
      setState(() {
        _templates = res.body['data'] as List? ?? [];
      });
    }
  }

  void _applyTemplate(Map<String, dynamic> mappings) {
    setState(() {
      _fieldMappings.clear();
      mappings.forEach((key, val) {
        final intIndex = int.tryParse(val.toString());
        if (intIndex != null) {
          _fieldMappings[key] = intIndex;
          _numInputControllers[key]?.text = intIndex.toString();
        }
      });
    });
  }

  Future<void> _fetchPreviewData() async {
    setState(() => _loadingPreview = true);
    final apiMappings = _fieldMappings.map((key, val) => MapEntry(key, val.toString()));
    final res = await _leadsController.leadService.getImportPreview(widget.importId, apiMappings);
    if (!res.status.hasError && res.body != null) {
      setState(() {
        _previewValidationRows = res.body['data'] as List? ?? [];
      });
    }
    setState(() => _loadingPreview = false);
  }

  // Poll job status until completed/failed
  void _startPolling() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;

      final res = await _leadsController.leadService.getImportStatus(widget.importId);
      if (!res.status.hasError && res.body != null) {
        final data = res.body['data'];
        setState(() {
          _jobStatus = data['status'];
          _totalRows = data['totalRows'] ?? 0;
          _processedRows = data['processedRows'] ?? 0;
          _successfulRows = data['successfulRows'] ?? 0;
          _failedRows = data['failedRows'] ?? 0;
          _duplicateRows = data['duplicateRows'] ?? 0;
        });

        if (_jobStatus == 'completed' || _jobStatus == 'completed_with_errors' || _jobStatus == 'failed') {
          _fetchErrorLogs();
          return false;
        }
      }
      return true;
    });
  }

  Future<void> _fetchErrorLogs() async {
    final res = await _leadsController.leadService.getImportErrors(widget.importId);
    if (!res.status.hasError && res.body != null) {
      setState(() {
        _errorLogs = res.body['data'] as List? ?? [];
      });
    }
  }

  void _downloadErrorReport() {
    if (_errorLogs.isEmpty) return;
    
    // Construct CSV file
    String csv = "Row Number,Error,Raw Row Data\n";
    for (final err in _errorLogs) {
      final rawStr = jsonEncode(err['rawData']).replaceAll('"', '""');
      csv += "${err['rowNumber']},\"${err['errorText']}\",\"$rawStr\"\n";
    }
    
    final blob = html.Blob([csv], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "import_error_report_${widget.importId}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // --- WIZARD ACTIONS ---
  Future<void> _startImportAction() async {
    setState(() => _isProcessing = true);

    // Save Template if option selected
    if (_saveAsTemplate && _templateNameCtrl.text.isNotEmpty) {
      await _leadsController.leadService.saveTemplate(
        _templateNameCtrl.text,
        _fieldMappings.map((key, val) => MapEntry(key, val.toString())),
      );
    }

    // Map Stringified mappings for API
    final apiMappings = _fieldMappings.map((key, val) => MapEntry(key, val.toString()));

    final res = await _leadsController.leadService.startImport(widget.importId, {
      'mapping': apiMappings,
      'selectedSheet': _selectedSheet,
      'importOptions': {
        'duplicateHandling': _duplicateStrategy,
        'assignedRM': _assignedRM,
        'stage': _leadStage,
        'leadPoolId': _selectedLeadPoolId,
      }
    });

    setState(() {
      _isProcessing = false;
      if (!res.status.hasError) {
        _currentStep = 3; // Navigate to status screen
        _startPolling();
      } else {
        Get.snackbar('Import Error', res.body?['message'] ?? 'Failed to start import job.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1000,
        height: 680,
        padding: const EdgeInsets.all(28),
        child: _loadingFields
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildStepProgress(),
                  const SizedBox(height: 24),
                  Expanded(child: _buildStepBody()),
                  const SizedBox(height: 16),
                  _buildNavigationButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Bulk Lead Import Wizard',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_jobStatus == 'processing') {
              Get.snackbar('Wait', 'Import is processing in background. You can close this safety dialog.');
            }
            Get.back();
          },
        ),
      ],
    );
  }

  Widget _buildStepProgress() {
    return Row(
      children: [
        _buildStepIndicator(step: 1, label: 'Mapping Configurations'),
        _buildStepDivider(),
        _buildStepIndicator(step: 2, label: 'Options & Review'),
        _buildStepDivider(),
        _buildStepIndicator(step: 3, label: 'Processing Logs'),
      ],
    );
  }

  Widget _buildStepIndicator({required int step, required String label}) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? AppTheme.successGreen
                : (isActive ? AppTheme.primaryBlue : AppTheme.gray300),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    step.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppTheme.textPrimary : AppTheme.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 1,
        color: AppTheme.gray300,
        margin: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_currentStep) {
      case 1:
        return _buildMappingStep();
      case 2:
        return _buildOptionsStep();
      case 3:
        return _buildProgressStep();
      default:
        return const SizedBox();
    }
  }

  // --- STEP 1: MAPPING STEP VIEW ---
  Widget _buildMappingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Templates & Sheet selection
        if (widget.sheetNames.length > 1 || _templates.isNotEmpty) ...[
          Row(
            children: [
              if (widget.sheetNames.length > 1) ...[
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Excel Sheet', border: OutlineInputBorder()),
                    value: _selectedSheet,
                    items: widget.sheetNames.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSheet = val);
                    },
                  ),
                ),
                if (_templates.isNotEmpty) const SizedBox(width: 24),
              ],
              if (_templates.isNotEmpty)
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Use Mapping Template (Optional)', border: OutlineInputBorder()),
                    value: _selectedTemplateId,
                    items: _templates.map((t) {
                      return DropdownMenuItem<String>(
                        value: t['_id'].toString(),
                        child: Text(t['name'].toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTemplateId = val);
                        final tmpl = _templates.firstWhere((t) => t['_id'] == val);
                        _applyTemplate(tmpl['mappings'] as Map<String, dynamic>);
                      }
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        const Divider(color: AppTheme.gray200),
        const SizedBox(height: 8),

        // Mapping Table Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('CRM LEAD FIELD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.gray600))),
              Expanded(flex: 3, child: Text('EXCEL COLUMN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.gray600))),
              Expanded(flex: 1, child: Text('COL #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.gray600))),
              Expanded(flex: 3, child: Text('SAMPLE DATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.gray600))),
            ],
          ),
        ),

        // Mapping rows list
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: AppTheme.gray200), borderRadius: BorderRadius.circular(8)),
            child: ListView.separated(
              itemCount: _crmFields.length,
              separatorBuilder: (context, idx) => const Divider(height: 1, color: AppTheme.gray200),
              itemBuilder: (context, idx) {
                final field = _crmFields[idx];
                final key = field['key'] as String;
                final label = field['label'] as String;
                final isRequired = field['required'] == true;

                final mappedIndex = _fieldMappings[key];
                String sampleValue = '—';
                if (mappedIndex != null && mappedIndex > 0 && widget.previewRows.isNotEmpty) {
                  // Get sample value from previewRows
                  final row = widget.previewRows.first;
                  List<String> keys = [];
                  if (row is Map) {
                    keys = row.keys.map((k) => k.toString()).toList();
                  }
                  if (mappedIndex - 1 < keys.length) {
                    sampleValue = (row[keys[mappedIndex - 1]] ?? '—').toString();
                  }
                }

                // Check suggested mapped label
                final suggestion = widget.suggestedMapping[key];
                final hasSuggestion = suggestion != null && mappedIndex == suggestion['columnIndex'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Field Label
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Text(
                              label,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            if (isRequired)
                              const Text(' *', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      // Column Selector Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            suffixIcon: hasSuggestion
                                ? Container(
                                    padding: const EdgeInsets.all(4),
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Tooltip(
                                      message: 'Matched automatically with ${suggestion['confidence']}% confidence',
                                      child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                                    ),
                                  )
                                : null,
                          ),
                          value: mappedIndex,
                          hint: const Text('Not Mapped', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem<int>(value: null, child: Text('Not Mapped', style: TextStyle(fontSize: 13))),
                            ...widget.columnPreview.map((col) {
                              final index = col['index'] as int;
                              return DropdownMenuItem<int>(
                                value: index,
                                child: Text('${col['index']} - ${col['letter']} (${col['header']})', style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _fieldMappings[key] = val!;
                              _numInputControllers[key]?.text = val?.toString() ?? '';
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Numeric Column Input (Manual typing)
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _numInputControllers[key],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onChanged: (val) {
                            final parsedIdx = int.tryParse(val);
                            if (parsedIdx != null && parsedIdx > 0 && parsedIdx <= widget.columnPreview.length) {
                              setState(() {
                                _fieldMappings[key] = parsedIdx;
                              });
                            } else if (val.isEmpty) {
                              setState(() {
                                _fieldMappings.remove(key);
                              });
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Sample Value Preview
                      Expanded(
                        flex: 3,
                        child: Text(
                          sampleValue,
                          style: const TextStyle(fontSize: 13, color: AppTheme.gray500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: OPTIONS & VALIDATION PREVIEW VIEW ---
  Widget _buildOptionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Import Settings & Default Values',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            // Duplicate Resolution
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Duplicate Handling Strategy', border: OutlineInputBorder()),
                value: _duplicateStrategy,
                items: const [
                  DropdownMenuItem(value: 'skip', child: Text('Skip Duplicates (Recommended)')),
                  DropdownMenuItem(value: 'update', child: Text('Overwrite/Update existing lead')),
                  DropdownMenuItem(value: 'create', child: Text('Create duplicate record')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _duplicateStrategy = val);
                },
              ),
            ),
            const SizedBox(width: 24),
            // Default RM
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Default Owner / RM', border: OutlineInputBorder()),
                value: _assignedRM,
                hint: const Text('None'),
                items: [
                  const DropdownMenuItem<String>(value: null, child: Text('None (Leave Unassigned)')),
                  ..._leadsController.staffList.map((s) {
                    return DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.fullName),
                    );
                  }).toList(),
                ],
                onChanged: (val) => setState(() => _assignedRM = val),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Default Stage & Lead Pool
            Expanded(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Default Lead Stage', border: OutlineInputBorder()),
                    value: _leadStage,
                    items: const [
                      DropdownMenuItem(value: 'New', child: Text('New')),
                      DropdownMenuItem(value: 'Contacted', child: Text('Contacted')),
                      DropdownMenuItem(value: 'Interested', child: Text('Interested')),
                      DropdownMenuItem(value: 'Qualified', child: Text('Qualified')),
                      DropdownMenuItem(value: 'Demo / Meeting Scheduled', child: Text('Demo / Meeting Scheduled')),
                      DropdownMenuItem(value: 'Demo / Meeting Completed', child: Text('Demo / Meeting Completed')),
                      DropdownMenuItem(value: 'Proposal Sent', child: Text('Proposal Sent')),
                      DropdownMenuItem(value: 'Negotiation', child: Text('Negotiation')),
                      DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
                      DropdownMenuItem(value: 'Won', child: Text('Won')),
                      DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                      DropdownMenuItem(value: 'On Hold', child: Text('On Hold')),
                      DropdownMenuItem(value: 'Not Interested', child: Text('Not Interested')),
                      DropdownMenuItem(value: 'Invalid', child: Text('Invalid')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _leadStage = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Target Lead Pool', border: OutlineInputBorder()),
                          value: _selectedLeadPoolId,
                          hint: const Text('None'),
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('None (Leave Unassigned)')),
                            ..._leadPools.map((p) {
                              return DropdownMenuItem<String>(
                                value: p['_id'].toString(),
                                child: Text(p['name'].toString()),
                              );
                            }).toList(),
                          ],
                          onChanged: (val) => setState(() => _selectedLeadPoolId = val),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: AppTheme.primaryBlue),
                        onPressed: _createNewLeadPoolDialog,
                        tooltip: 'Create New Lead Pool',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Re-usable mapping Template save option
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _saveAsTemplate,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (val) => setState(() => _saveAsTemplate = val ?? false),
                      ),
                      const Text('Save this column mapping as template for reuse'),
                    ],
                  ),
                  if (_saveAsTemplate) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _templateNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Template Name',
                        hintText: 'e.g. Website Leads Import Format',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: AppTheme.gray200),
        const SizedBox(height: 8),
        const Text(
          'Mapped Row Validation Previews',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loadingPreview
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
              : Container(
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.gray200), borderRadius: BorderRadius.circular(8)),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 1,
                    itemBuilder: (context, _) {
                      return DataTable(
                        columns: [
                          const DataColumn(label: Text('Status')),
                          ..._crmFields.map((f) => DataColumn(label: Text(f['label'] ?? ''))).toList(),
                        ],
                        rows: _previewValidationRows.map((row) {
                          final isValid = row['isValid'] == true;
                          final errs = row['errors'] as List? ?? [];
                          final mapped = row['mappedData'] as Map? ?? {};
                          
                          return DataRow(
                            cells: [
                              DataCell(
                                isValid
                                    ? const Icon(Icons.check_circle, color: AppTheme.successGreen, size: 18)
                                    : Tooltip(
                                        message: errs.join(", "),
                                        child: const Icon(Icons.warning, color: AppTheme.errorRed, size: 18),
                                      ),
                              ),
                              ..._crmFields.map((field) {
                                final key = field['key'] as String;
                                dynamic val;
                                if (key == 'city' || key == 'state') {
                                  val = mapped['personalDetails']?[key];
                                } else {
                                  val = mapped[key];
                                }
                                return DataCell(Text(val?.toString() ?? '—'));
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // --- STEP 3: PROGRESS STEP VIEW ---
  Widget _buildProgressStep() {
    final isDone = _jobStatus == 'completed' || _jobStatus == 'completed_with_errors';
    final isFailed = _jobStatus == 'failed';
    final progress = _totalRows > 0 ? _processedRows / _totalRows : 0.0;

    return Center(
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_jobStatus == 'processing') ...[
              const CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(height: 24),
              Text(
                'Processing leads: $_processedRows / $_totalRows rows',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.gray200,
                color: AppTheme.skyBlue,
                minHeight: 10,
              ),
            ] else if (isDone) ...[
              Icon(Icons.check_circle_outline, size: 72, color: AppTheme.successGreen),
              const SizedBox(height: 16),
              const Text('Import Process Completed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildStatsSummary(),
              const SizedBox(height: 18),
              if (_errorLogs.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: _downloadErrorReport,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download Error Report CSV'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorRed,
                    side: const BorderSide(color: AppTheme.errorRed),
                  ),
                ),
              ],
            ] else if (isFailed) ...[
              const Icon(Icons.error_outline, size: 72, color: AppTheme.errorRed),
              const SizedBox(height: 16),
              const Text('Import Failed!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.errorRed)),
              const SizedBox(height: 12),
              const Text('An internal parser error occurred during batch processing. Please check the logs.'),
            ] else ...[
              const Text('Preparing job...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.gray200),
      ),
      child: Column(
        children: [
          _buildStatRow('Total Leads Processed:', _totalRows),
          const Divider(),
          _buildStatRow('Added Successfully:', _successfulRows, color: AppTheme.successGreen),
          _buildStatRow('Skipped (Duplicates):', _duplicateRows, color: AppTheme.primaryBlue),
          _buildStatRow('Failed (Validation errors):', _failedRows, color: AppTheme.errorRed),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          Text(
            val.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --- BUTTON NAVIGATION ---
  Widget _buildNavigationButtons() {
    if (_currentStep == 3) {
      // Step 3 shows the completed/processing states
      final isFinished = _jobStatus == 'completed' || _jobStatus == 'completed_with_errors' || _jobStatus == 'failed';
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: isFinished
                ? () {
                    _leadsController.fetchLeads();
                    Get.back();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text('Finish'),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_currentStep > 1) ...[
          OutlinedButton(
            onPressed: _isProcessing ? null : () => setState(() => _currentStep--),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text('Back'),
          ),
          const SizedBox(width: 12),
        ],
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () {
                  if (_currentStep == 1) {
                    // Check required fields
                    for (final f in _crmFields) {
                      if (f['required'] == true) {
                        final key = f['key'] as String;
                        if (!_fieldMappings.containsKey(key) || _fieldMappings[key] == null) {
                          Get.snackbar('Missing Field', 'Please map the required field: ${f['label']}', backgroundColor: Colors.orange.withOpacity(0.1));
                          return;
                        }
                      }
                    }
                    _fetchPreviewData();
                    setState(() => _currentStep++);
                  } else if (_currentStep == 2) {
                    _startImportAction();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          child: Text(_currentStep == 2 ? 'Start Import' : 'Next'),
        ),
      ],
    );
  }
}


