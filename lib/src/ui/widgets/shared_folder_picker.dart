import 'package:flutter/material.dart';

class SharedFolder {
  final String hostPath;
  final String guestPath;
  final bool readOnly;

  SharedFolder({
    required this.hostPath,
    required this.guestPath,
    this.readOnly = false,
  });
}

class SharedFolderPicker extends StatefulWidget {
  final List<SharedFolder> initialFolders;
  final void Function(List<SharedFolder>) onChanged;

  const SharedFolderPicker({
    super.key,
    required this.initialFolders,
    required this.onChanged,
  });

  @override
  State<SharedFolderPicker> createState() => _SharedFolderPickerState();
}

class _SharedFolderPickerState extends State<SharedFolderPicker> {
  late List<SharedFolder> _folders;

  @override
  void initState() {
    super.initState();
    _folders = List.from(widget.initialFolders);
  }

  void _addFolder() {
    showDialog(
      context: context,
      builder: (context) => _SharedFolderDialog(
        onSave: (folder) {
          setState(() => _folders.add(folder));
          widget.onChanged(_folders);
        },
      ),
    );
  }

  void _editFolder(int index) {
    showDialog(
      context: context,
      builder: (context) => _SharedFolderDialog(
        initial: _folders[index],
        onSave: (folder) {
          setState(() => _folders[index] = folder);
          widget.onChanged(_folders);
        },
      ),
    );
  }

  void _removeFolder(int index) {
    setState(() => _folders.removeAt(index));
    widget.onChanged(_folders);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shared Folders', style: Theme.of(context).textTheme.titleSmall),
            IconButton(icon: const Icon(Icons.add), onPressed: _addFolder),
          ],
        ),
        if (_folders.isEmpty)
          Text(
            'No shared folders configured',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (var i = 0; i < _folders.length; i++)
          ListTile(
            title: Text(_folders[i].hostPath),
            subtitle: Text('${_folders[i].guestPath}${_folders[i].readOnly ? " (read-only)" : ""}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editFolder(i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeFolder(i),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SharedFolderDialog extends StatefulWidget {
  final SharedFolder? initial;
  final void Function(SharedFolder) onSave;

  const _SharedFolderDialog({required this.onSave, this.initial});

  @override
  State<_SharedFolderDialog> createState() => _SharedFolderDialogState();
}

class _SharedFolderDialogState extends State<_SharedFolderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostPathController;
  late final TextEditingController _guestPathController;
  late bool _readOnly;

  @override
  void initState() {
    super.initState();
    _hostPathController = TextEditingController(
      text: widget.initial?.hostPath ?? '',
    );
    _guestPathController = TextEditingController(
      text: widget.initial?.guestPath ?? '/mnt/host',
    );
    _readOnly = widget.initial?.readOnly ?? false;
  }

  @override
  void dispose() {
    _hostPathController.dispose();
    _guestPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Shared Folder' : 'Edit Shared Folder'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _hostPathController,
              decoration: const InputDecoration(labelText: 'Host Path'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _guestPathController,
              decoration: const InputDecoration(labelText: 'Guest Mount Path'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            SwitchListTile(
              title: const Text('Read Only'),
              value: _readOnly,
              onChanged: (v) => setState(() => _readOnly = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                SharedFolder(
                  hostPath: _hostPathController.text,
                  guestPath: _guestPathController.text,
                  readOnly: _readOnly,
                ),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}