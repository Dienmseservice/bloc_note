import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/user_model.dart';
import '../models/note_model.dart'; 

class NoteFormView extends StatefulWidget {
  final UserModel user;
  final NoteModel? note; 

  const NoteFormView({
    super.key,
    required this.user,
    this.note,
  });

  @override
  State<NoteFormView> createState() => _NoteFormViewState();
}

class _NoteFormViewState extends State<NoteFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _selectedCategory = 'Général';
  bool _isSaving = false;

  bool get _isEditMode => widget.note != null;

  final List<String> _categories = ['Général', 'Personnel', 'Travail', 'Idées'];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _selectedCategory = widget.note!.category;
    }
  }

  void _saveNote() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      if (_isEditMode) {
        final updatedNote = NoteModel(
          id: widget.note!.id,
          userId: widget.note!.userId,
          title: title,
          content: content,
          category: _selectedCategory,
          isArchived: widget.note!.isArchived,
          createdAt: widget.note!.createdAt,
        );
        await DatabaseHelper.instance.updateNote(updatedNote);
      } else {
        final newNote = NoteModel(
          title: title,
          content: content,
          category: _selectedCategory,
          createdAt: DateTime.now().toIso8601String(),
        );
        await DatabaseHelper.instance.createNote(newNote, widget.user.id!);
      }

      if (!mounted) return;
      Navigator.pop(context, true); 
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color emeraldGreen = Color(0xFF059669);
    const Color anthraciteGray = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditMode ? 'Modifier la note' : 'Nouvelle note',
          style: const TextStyle(color: anthraciteGray, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: anthraciteGray),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: CircularProgressIndicator(color: emeraldGreen)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: emeraldGreen, size: 28),
              onPressed: _saveNote,
            )
        ],
      ),
      body: SafeArea(
        child: Padding(
          // 🔴 CORRECTION SÉCURISÉE ICI : Remplacement par EdgeInsets.all pour éviter tout conflit de syntaxe
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Catégorie de la note',
                    labelStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: emeraldGreen),
                    ),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: const TextStyle(color: anthraciteGray)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: anthraciteGray),
                  decoration: const InputDecoration(
                    hintText: 'Titre',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Donnez un titre à votre note' : null,
                ),
                const Divider(),
                Expanded(
                  child: TextFormField(
                    controller: _contentController,
                    maxLines: null, 
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(fontSize: 16, color: anthraciteGray),
                    decoration: const InputDecoration(
                      hintText: 'Commencez à écrire...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Le contenu ne peut pas être vide' : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}