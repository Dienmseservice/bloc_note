import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/note_model.dart';
import '../services/database_helper.dart';
import 'profile_view.dart';
import 'trash_view.dart'; 
import 'note_form_view.dart'; // Importation indispensable de ton nouvel écran

class NotesListView extends StatefulWidget {
  final UserModel user;
  const NotesListView({super.key, required this.user});

  @override
  State<NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends State<NotesListView> {
  List<NoteModel> _allNotes = [];      // Liste source complète
  List<NoteModel> _filteredNotes = []; // Liste filtrée affichée à l'écran
  bool _isLoading = true;
  late UserModel _currentUser;
  
  String _searchQuery = '';
  double _dbSizeKB = 0.0;
  double _co2SavedMg = 0.0;

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Personnel': return Colors.blue.shade400;
      case 'Travail': return Colors.orange.shade400;
      case 'Idées': return Colors.purple.shade400;
      default: return const Color(0xFF059669); // Vert émeraude par défaut
    }
  }

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _refreshNotes();
  }

  // Recharge la liste et met à jour les métriques d'impact environnemental
  Future<void> _refreshNotes() async {
    setState(() => _isLoading = true);
    
    final data = await DatabaseHelper.instance.readUserNotes(_currentUser.id!);
    final metrics = await DatabaseHelper.instance.getEcoImpactMetrics();
    
    setState(() {
      _allNotes = data;
      _dbSizeKB = metrics['size'] ?? 0.0;
      _co2SavedMg = metrics['co2'] ?? 0.0;
      _applySearchFilter(_searchQuery); // Maintient le filtrage s'il y en a un
      _isLoading = false;
    });
  }

  // Filtrage mémoire ultra-rapide (Pas d'appel SQL = Batterie préservée)
  void _applySearchFilter(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredNotes = List.from(_allNotes);
    } else {
      _filteredNotes = _allNotes.where((note) {
        return note.title.toLowerCase().contains(query.toLowerCase()) ||
               note.content.toLowerCase().contains(query.toLowerCase()) ||
               note.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  // REDIRECTION : Gère maintenant la navigation vers NoteFormView pour l'Ajout et la Modification
  Future<void> _navigateToNoteForm(NoteModel? note) async {
    final bool? shouldRefresh = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteFormView(
          user: _currentUser,
          note: note, // Si nul -> mode création. Si fourni -> mode modification.
        ),
      ),
    );

    // Si la page NoteFormView renvoie true, on recharge les données locales
    if (shouldRefresh == true) {
      _refreshNotes();
    }
  }

  void _softDeleteNote(int id) async {
    await DatabaseHelper.instance.moveToTrash(id);
    _refreshNotes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note déplacée dans la corbeille éco-responsable.'),
        backgroundColor: Color(0xFF1F2937),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color emeraldGreen = Color(0xFF059669);
    const Color anthraciteGray = Color(0xFF1F2937);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Notes de ${_currentUser.fullName}'),
        backgroundColor: Colors.white,
        foregroundColor: anthraciteGray,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.orangeAccent, size: 26),
            tooltip: 'Corbeille',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TrashView(userId: _currentUser.id!)),
              );
              _refreshNotes();
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: emeraldGreen, size: 28),
            onPressed: () async {
              final updatedUser = await Navigator.push<UserModel>(
                context,
                MaterialPageRoute(builder: (context) => ProfileView(user: _currentUser)),
              );
              if (updatedUser != null) {
                setState(() => _currentUser = updatedUser);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 📊 PANNEAU D'IMPACT ÉCO-NUMÉRIQUE INNOVANT
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: emeraldGreen.withAlpha((0.08 * 255).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: emeraldGreen.withAlpha((0.3 * 255).round())),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco, color: emeraldGreen, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Indice EcoSave local',
                        style: TextStyle(fontWeight: FontWeight.bold, color: anthraciteGray),
                      ),
                      Text(
                        'Base locale : ${_dbSizeKB.toStringAsFixed(1)} Ko | CO₂ évité : ${_co2SavedMg.toStringAsFixed(2)} mg',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 🔍 BARRE DE RECHERCHE DYNAMIQUE ÉCO-CONÇUE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => _applySearchFilter(value)),
              decoration: InputDecoration(
                hintText: 'Rechercher une note ou un tag...',
                prefixIcon: const Icon(Icons.search, color: emeraldGreen),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 📝 LISTE DES NOTES FILTRÉES
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: emeraldGreen))
                : _filteredNotes.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'Aucune note pour le moment' : 'Aucun résultat trouvé',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredNotes.length,
                        itemBuilder: (context, index) {
                          final note = _filteredNotes[index];
                          final tagColor = _getCategoryColor(note.category);

                          return Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              title: Row(
                                children: [
                                  // 🏷️ TAG DE CATÉGORIE VISUEL
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: tagColor.withAlpha((0.15 * 255).round()),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      note.category,
                                      style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: anthraciteGray),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top:6.0),
                                child: Text(
                                  note.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade600, height: 1.3),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: emeraldGreen),
                                    // Clique sur le bouton modifier -> ouvre l'écran dédié avec les données de la note
                                    onPressed: () => _navigateToNoteForm(note),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_sweep_outlined, color: Colors.orangeAccent),
                                    tooltip: 'Mettre à la corbeille',
                                    onPressed: () => _softDeleteNote(note.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        // Clique sur le bouton plus (+) -> ouvre l'écran dédié en lui transmettant "null"
        onPressed: () => _navigateToNoteForm(null),
        backgroundColor: emeraldGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}