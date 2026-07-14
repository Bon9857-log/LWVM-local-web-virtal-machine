import 'package:flutter/material.dart';

class PortForward {
  final int hostPort;
  final int guestPort;
  final String description;

  PortForward({
    required this.hostPort,
    required this.guestPort,
    this.description = '',
  });
}

class PortForwardEditor extends StatefulWidget {
  final List<PortForward> initialForwards;
  final void Function(List<PortForward>) onChanged;

  const PortForwardEditor({
    super.key,
    required this.initialForwards,
    required this.onChanged,
  });

  @override
  State<PortForwardEditor> createState() => _PortForwardEditorState();
}

class _PortForwardEditorState extends State<PortForwardEditor> {
  late List<PortForward> _forwards;

  @override
  void initState() {
    super.initState();
    _forwards = List.from(widget.initialForwards);
  }

  void _addForward() {
    showDialog(
      context: context,
      builder: (context) => _PortForwardDialog(
        onSave: (forward) {
          setState(() => _forwards.add(forward));
          widget.onChanged(_forwards);
        },
      ),
    );
  }

  void _editForward(int index) {
    showDialog(
      context: context,
      builder: (context) => _PortForwardDialog(
        initial: _forwards[index],
        onSave: (forward) {
          setState(() => _forwards[index] = forward);
          widget.onChanged(_forwards);
        },
      ),
    );
  }

  void _removeForward(int index) {
    setState(() => _forwards.removeAt(index));
    widget.onChanged(_forwards);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Port Forwards', style: Theme.of(context).textTheme.titleSmall),
            IconButton(icon: const Icon(Icons.add), onPressed: _addForward),
          ],
        ),
        if (_forwards.isEmpty)
          Text(
            'No port forwards configured',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        for (var i = 0; i < _forwards.length; i++)
          ListTile(
            title: Text('${_forwards[i].guestPort} -> ${_forwards[i].hostPort}'),
            subtitle: _forwards[i].description.isNotEmpty
                ? Text(_forwards[i].description)
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editForward(i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeForward(i),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PortForwardDialog extends StatefulWidget {
  final PortForward? initial;
  final void Function(PortForward) onSave;

  const _PortForwardDialog({required this.onSave, this.initial});

  @override
  State<_PortForwardDialog> createState() => _PortForwardDialogState();
}

class _PortForwardDialogState extends State<_PortForwardDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostPortController;
  late final TextEditingController _guestPortController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _hostPortController = TextEditingController(
      text: widget.initial?.hostPort.toString() ?? '2222',
    );
    _guestPortController = TextEditingController(
      text: widget.initial?.guestPort.toString() ?? '22',
    );
    _descriptionController = TextEditingController(
      text: widget.initial?.description ?? '',
    );
  }

  @override
  void dispose() {
    _hostPortController.dispose();
    _guestPortController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Port Forward' : 'Edit Port Forward'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _hostPortController,
              decoration: const InputDecoration(labelText: 'Host Port'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final port = int.tryParse(v);
                if (port == null || port < 1 || port > 65535) {
                  return 'Invalid port';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _guestPortController,
              decoration: const InputDecoration(labelText: 'Guest Port'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final port = int.tryParse(v);
                if (port == null || port < 1 || port > 65535) {
                  return 'Invalid port';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
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
                PortForward(
                  hostPort: int.parse(_hostPortController.text),
                  guestPort: int.parse(_guestPortController.text),
                  description: _descriptionController.text,
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