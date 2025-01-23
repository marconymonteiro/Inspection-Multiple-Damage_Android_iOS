import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'editar_formulario.dart';

class SavedForms extends StatefulWidget {
  @override
  _ConsultaFormulariosState createState() => _ConsultaFormulariosState();
}

class _ConsultaFormulariosState extends State<SavedForms> {
  List<String> _savedForms = [];
  List<String> _filteredForms = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedForms();

    // Listener para atualizar a lista filtrada
    _searchController.addListener(() async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _filteredForms = _savedForms.where((formId) {
          final name = prefs.getString('$formId-name') ?? '';
          final serialNumber = prefs.getString('$formId-serialNumber') ?? '';
          final invoiceNumber = prefs.getString('$formId-invoiceNumber') ?? '';
          final query = _searchController.text.toLowerCase();
          return name.toLowerCase().contains(query) ||
              serialNumber.toLowerCase().contains(query) ||
              invoiceNumber.toLowerCase().contains(query);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Carrega os identificadores dos formulários salvos
  Future<void> _loadSavedForms() async {
    final prefs = await SharedPreferences.getInstance();
    final savedForms = prefs.getStringList('savedForms') ?? [];
    setState(() {
      _savedForms = savedForms.reversed.toList();
      _filteredForms = _savedForms; // Inicialmente, exibe todos
    });
  }

  // Remove um formulário
  Future<void> _deleteForm(String formId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedForms.remove(formId);
      _filteredForms.remove(formId);
    });
    // Remove os dados do formulário
    await prefs.remove(formId);
    await prefs.remove('$formId-name');
    await prefs.remove('$formId-equipment');
    await prefs.remove('$formId-serialNumber');
    await prefs.remove('$formId-invoiceNumber');
    await prefs.remove('$formId-damageDescription');

    // Atualiza a lista de IDs salvos
    await prefs.setStringList('savedForms', _savedForms);

    // Recarrega os formulários salvos
    _loadSavedForms();
  }

  // Mostra o pop-up de confirmação para exclusão
  void _confirmDelete(BuildContext context, String formId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir este formulário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o diálogo
              _deleteForm(formId); // Exclui o formulário
            },
            child: Text('Sim'),
          ),
        ],
      ),
    );
  }

  // Carrega os dados de um formulário salvo com base no id
  Future<Map<String, String>> _loadFormData(String formId) async {
    final prefs = await SharedPreferences.getInstance();
    final formData = <String, String>{};
    formData['name'] = prefs.getString('$formId-name') ?? '';
    formData['equipment'] = prefs.getString('$formId-equipment') ?? '';
    formData['serialNumber'] = prefs.getString('$formId-serialNumber') ?? '';
    formData['invoiceNumber'] = prefs.getString('$formId-invoiceNumber') ?? '';
    formData['damageDescription'] =
        prefs.getString('$formId-damageDescription') ?? '';
    return formData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Formulários Salvos')),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar formulários',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          // Lista de formulários
          Expanded(
            child: ListView.builder(
              itemCount: _filteredForms.length,
              itemBuilder: (context, index) {
                final formId = _filteredForms[index];
                return FutureBuilder<Map<String, String>>(
                  future: _loadFormData(formId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasData) {
                      final formData = snapshot.data!;
                      return ListTile(
                        title: Text(formData['equipment'] ?? 'Equipamento'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Número de Série: ${formData['serialNumber'] ?? ''}'),
                            Text('Nota Fiscal: ${formData['invoiceNumber'] ?? ''}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, formId),
                        ),
                        onTap: () {
                          // Navegar para edição
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditarFormulario(formId: formId),
                            ),
                          );
                        },
                      );
                    }
                    return const Text('Erro ao carregar o formulário');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
