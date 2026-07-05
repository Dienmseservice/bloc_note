import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/database_helper.dart';

class TrashView extends StatefulWidget {
  final int userId;
  const TrashView({super.key, required this.userId});

  @override
  State<TrashView> createState() => _TrashViewState();
}

class _TrashViewState extends State<TrashView> {
  List<NoteModel> _trashNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrashNotes();
  }

  Future<void> _loadTrashNotes() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.readTrashNotes(widget.userId);
    setState(() {
      _trashNotes = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Corbeille Éco-Responsable'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : _trashNotes.isEmpty
              ? const Center(
                  child: Text('La corbeille est vide.', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _trashNotes.length,
                  itemBuilder: (context, index) {
                    final note = _trashNotes[index];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(note.content, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.restore, color: Color(0xFF059669)),
                              tooltip: 'Restaurer',
                              onPressed: () async {
                                await DatabaseHelper.instance.restoreFromTrash(note.id!);
                                _loadTrashNotes();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                              tooltip: 'Supprimer définitivement',
                              onPressed: () async {
                                await DatabaseHelper.instance.deleteNotePermanent(note.id!);
                                _loadTrashNotes();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}