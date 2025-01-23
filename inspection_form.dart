import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:share_extend/share_extend.dart';
import 'pdf_generator.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;

class FormularioInspecao extends StatefulWidget {
  final String formId; // ID do formulário a ser editado
  FormularioInspecao({required this.formId});
  @override
  _FormularioInspecaoState createState() => _FormularioInspecaoState();
}

class _FormularioInspecaoState extends State<FormularioInspecao> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(), // controlador para o campo "Motorista"
    'cargo': TextEditingController(), // controlador para o campo "Carga"
    'serialNumber': TextEditingController(),
    'invoiceNumber': TextEditingController(),
    'damageDescription': TextEditingController(),
    'codigo': TextEditingController(), // Novo controlador para o campo "Código"
    'equipment': TextEditingController(), // Novo controlador para o campo "Equipamento"
    'freight': TextEditingController(), // Novo controlador para o campo "transportadora"
    'plate': TextEditingController(), // Novo controlador para o campo "placas"
    'driverID': TextEditingController(), // Novo controlador para o campo "CPF"
    'model': TextEditingController(), // Novo controlador para o campo "modelo"
    'sanyRef': TextEditingController(), // Novo controlador para o campo "Referência Sany"
    'invoiceQtty': TextEditingController(), // Novo controlador para o campo "Quantidade de Volumes"
    'invoiceItems': TextEditingController(), // Novo controlador para o campo "Quantidade Partes e Peças"
  };

  // String _currentDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  DateTime? _selectedDate; // PARA NOVO PICKDATETIME

  String _hasDamage = 'Selecione'; // Variável para controlar o estado de seleção de dano
  List<Map<String, Object>> _damages = []; // Lista que conterá mapas com tipos garantidos
  Map<String, Object>? convertedMap; // Inicialize como nulo, será usado após a conversão
  String _damageDescription = ''; // Descrição do dano
  List<File> _damagePhotos = []; // Lista de fotos relacionadas a danos
  final List<File> _photosCarga = []; // Lista final de fotos de carga

  String damageJsonDecode(String jsonString) {
  // Implementação para decodificar o JSON
  return jsonString; // Exemplo simples
  }

  void _addPhotoToDamage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _damagePhotos.add(File(image.path));
      });
    }
  }

void _saveDamage() {
  if (_damageDescription.trim().isNotEmpty || _damagePhotos.isNotEmpty) {
    try {
      // Criamos o mapa dinâmico inicialmente
      Map<String, dynamic> dynamicMap = {
        'description': _damageDescription.trim(),
        'photos': List<File>.from(_damagePhotos),
      };

      // Convertendo o mapa dinâmico para garantir o tipo correto
      Map<String, Object> convertedMap = Map<String, Object>.from(dynamicMap);

      setState(() {
        _damages.add(convertedMap); // Adicionamos o mapa convertido à lista
        _damageDescription = ''; // Limpa a descrição
        _damagePhotos.clear(); // Limpa a lista de fotos
      });

      print('Dano salvo com sucesso: $convertedMap');
    } catch (e) {
      print('Erro ao salvar dano: $e');
    }
  } else {
    print('Nenhum dano foi fornecido para salvar.');
  }
}

  void _removeDamage(int index) {
    setState(() {
      _damages.removeAt(index);
    });
  }

  void _editDamage(int index) {
  final damage = _damages[index];
  setState(() {
    _damageDescription = damage['description'] as String; // Casting explícito para String
    _damagePhotos = List<File>.from(damage['photos'] as List); // Casting para List
    _damages.removeAt(index);
  });
}

void _showPhoto(File photo, {required VoidCallback onDelete}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.file(photo),
          const SizedBox(height: 16), // Adiciona espaçamento entre a imagem e os botões
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () async {
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Excluir Imagem'),
                        content: const Text('Tem certeza de que deseja excluir esta imagem?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      );
                    },
                  );
                  if (shouldDelete == true) {
                    onDelete();
                    Navigator.pop(context); // Fecha o diálogo principal
                  }
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Excluir'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

//  String _hasDamage = 'Selecione';
  final List<File> _photosDamage = [];
  String reportDate = ""; // Variável para armazenar a data formatada.

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('pt', 'BR'),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

        // Formatando para dd/MM/yyyy HH:mm
        reportDate = DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!);
        print('Data e hora selecionadas: $reportDate'); // Verifique no console
        });
      }
    }
  }

  Future<void> _saveForm() async {
  if (!_formKey.currentState!.validate()) return;

  final prefs = await SharedPreferences.getInstance();

  try {
    // Salvar dados do formulário
    for (var entry in _controllers.entries) {
      await prefs.setString('${widget.formId}-${entry.key}', entry.value.text);
    }
    await prefs.setString('${widget.formId}-hasDamage', _hasDamage);
    await prefs.setStringList('${widget.formId}-photosCarga', _photosCarga.map((e) => e.path).toList());
    await prefs.setString('${widget.formId}-selectedDate', _selectedDate?.toIso8601String() ?? '');

    // Salvar danos como JSON
    final List<Map<String, dynamic>> damagesData = _damages.map((damage) {
      return {
        'description': damage['description'],
        'photos': (damage['photos'] as List<File>)
            .map((photo) => photo.path)
            .toList(),
      };
    }).toList();
    await prefs.setString('${widget.formId}-damages', jsonEncode(damagesData));

    // Adicionar o ID do formulário aos salvos
    final savedForms = prefs.getStringList('savedForms') ?? [];
    savedForms.add(widget.formId);
    await prefs.setStringList('savedForms', savedForms);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Formulário editado com sucesso!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro ao salvar o formulário.')),
    );
  }
}

Future<void> _loadForm() async {
  final prefs = await SharedPreferences.getInstance();
  
  setState(() {
    for (var entry in _controllers.entries) {
      entry.value.text = prefs.getString('${widget.formId}-${entry.key}') ?? '';
    }
    _hasDamage = prefs.getString('${widget.formId}-hasDamage') ?? 'Selecione';
    _photosCarga.addAll(
      (prefs.getStringList('${widget.formId}-photosCarga') ?? [])
          .map((path) => File(path)),
    );
    _selectedDate = prefs.getString('${widget.formId}-selectedDate') != null
        ? DateTime.parse(prefs.getString('${widget.formId}-selectedDate')!)
        : null;

    final damagesJson = prefs.getString('${widget.formId}-damages');
    if (damagesJson != null) {
      try {
        final decodedDamages = jsonDecode(damagesJson) as List<dynamic>;
        _damages = decodedDamages.map((damage) {
          return {
            'description': damage['description'] as String,
            'photos': (damage['photos'] as List<dynamic>)
                .map((path) => File(path as String))
                .toList(),
          };
        }).toList();
      } catch (e) {
        _damages = [];
      }
    }
  });
}

Future<Uint8List> _compressImage(File image) async {
    final bytes = await image.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    final compressedImage = img.encodeJpg(decodedImage!, quality: 50);
    return Uint8List.fromList(compressedImage);
  }

  Future<void> _pickImage(List<File> photoList) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final tempFile = File(photo.path);
      final compressedBytes = await _compressImage(tempFile);

      // Salvar a imagem compactada em um arquivo temporário
      final compressedFile = await File(tempFile.path)
          .writeAsBytes(compressedBytes);

      setState(() {
        photoList.add(compressedFile);
      });
    }
  }

  void _removeImage(List<File> photoList, int index) {
    setState(() {
      photoList.removeAt(index);
    });
  }

  Widget _buildPhotoPreview(List<File> photos, List<File> photoList) {
    return photos.isNotEmpty
        ? Wrap(
            spacing: 8,
            runSpacing: 8, // Adiciona espaçamento vertical entre as linhas

            children: photos.map((photo) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  GestureDetector(
                    onTap: () => _showFullImage(photo),
                    child: Image.file(photo, height: 100, width: 100, fit: BoxFit.cover),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _confirmDeletePhoto(photo, photoList),
                  ),
                SizedBox(height: 8), // Espaçamento vertical após cada imagem
                ],
              );
            }).toList(),
          )
        : const SizedBox();
  }

  Future<void> _confirmDeletePhoto(File photo, List<File> photoList) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Imagem'),
          content: const Text('Tem certeza que deseja excluir a imagem?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        photoList.remove(photo);
      });
    }
  }

  void _showFullImage(File photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(photo),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final pdfFile = await PdfGenerator().generatePdf(
      name: _controllers['name']!.text,
      cargo: _controllers['cargo']!.text,
      serialNumber: _controllers['serialNumber']!.text,
      invoiceNumber: _controllers['invoiceNumber']!.text,
      codigo: _controllers['codigo']!.text,
      equipment: _controllers['equipment']!.text,
      freight: _controllers['freight']!.text,
      plate: _controllers['plate']!.text,
      driverID: _controllers['driverID']!.text,
      model: _controllers['model']!.text,
      sanyRef: _controllers['sanyRef']!.text,
      invoiceQtty: _controllers['invoiceQtty']!.text,
      invoiceItems: _controllers['invoiceItems']!.text,

      reportDate: _selectedDate != null
          ? DateFormat('dd/mm/yyyy', 'pt_BR').format(_selectedDate!)
          : 'Data não selecionada',
      hasDamage: _hasDamage == 'Sim',
      damageDescription: _controllers['damageDescription']!.text,
      photosCarga: _photosCarga,
      photosDamage: _photosDamage,
      damagesData: _damages, //incluído para teste de emissão de PDF
    );

    await ShareExtend.share(pdfFile.path, 'application/pdf');
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Formulário de Inspeção')),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Data e Hora: ${_selectedDate != null ? DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!) : 'Selecione a data e hora'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDateTime,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._buildTextFormFields(),

              TextFormField(
              controller: _controllers['invoiceQtty'],
              keyboardType: TextInputType.number, // Define o teclado numérico
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Permite apenas números
              decoration: const InputDecoration(
                labelText: 'Quantidade de Volumes',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira a quantidade de volumes';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _controllers['invoiceItems'],
              keyboardType: TextInputType.number, // Define o teclado numérico
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Permite apenas números
              decoration: const InputDecoration(
                labelText: 'Quantidade Partes e Peças',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira a quantidade de partes e peças';
                }
                return null;
              },
            ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _pickImage(_photosCarga),
                child: const Text('Adicionar Fotos Carga'),
              ),
              _buildPhotoPreview(_photosCarga, _photosCarga),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _hasDamage,
                decoration: const InputDecoration(labelText: 'Há Danos?'),
                items: ['Selecione', 'Sim', 'Não'].map((value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _hasDamage = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_hasDamage == 'Sim') ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Descrição do Dano'),
                  onChanged: (value) {
                    _damageDescription = value;
                  },
                  initialValue: _damageDescription,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Adicionar Foto Dano'),
                  onPressed: () => _pickImage(_damagePhotos)
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8, // Adiciona espaçamento vertical entre as linhas
                  children: _damagePhotos.map((photo) {
                    return GestureDetector(
                      onTap: () => _showPhoto(photo, onDelete: () {
                        setState(() {
                          _damagePhotos.remove(photo);
                        });
                      }),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Image.file(
                            photo,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _confirmDeletePhoto(photo, _damagePhotos),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Salvar Dano'),
                  onPressed: _saveDamage,
                ),
                const SizedBox(height: 16),
                if (_damages.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _damages.length,
                    itemBuilder: (context, index) {
                      final damage = _damages[index];
                      return Card(
                        child: ListTile(
                          title: Text(damage['description'] as String),
                          subtitle: Wrap(
                            spacing: 8,
                            runSpacing: 8, // Adiciona espaçamento vertical entre as linhas
                              children: (damage['photos'] != null ? damage['photos'] as List<File> : []).map<Widget>((photo) {
                              return GestureDetector(
                                onTap: () => _showPhoto(photo, onDelete: () {
                                  setState(() {
                                      if (damage['photos'] != null && damage['photos'] is List<File>) {
                                      (damage['photos'] as List<File>).remove(photo);
                                    }                                                                    });
                                }),
                                child: Image.file(
                                  photo,
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }).toList(),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editDamage(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Excluir Dano'),
                                        content: const Text('Tem certeza que deseja excluir este dano?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text('Não'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text('Sim'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (shouldDelete ?? false) {
                                    setState(() {
                                      _damages.removeAt(index);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('Salvar Formulário'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Gerar PDF'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

List<Widget> _buildTextFormFields() {
  final fields = [
    {'key': 'codigo', 'label': 'Código'},
    {'key': 'equipment', 'label': 'Equipamento'},
    {'key': 'freight', 'label': 'Transportadora'},
    {'key': 'plate', 'label': 'Placas'},
    {'key': 'name', 'label': 'Nome do Motorista'},
    {'key': 'driverID', 'label': 'CPF'},
    {'key': 'model', 'label': 'Modelo'},
    {'key': 'cargo', 'label': 'Máquina'},
    {'key': 'serialNumber', 'label': 'Número de Série'},
    {'key': 'invoiceNumber', 'label': 'Número da Nota Fiscal'},
    {'key': 'sanyRef', 'label': 'Referência SANY'},
  ];

  return fields.map((field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controllers[field['key']],
          decoration: InputDecoration(labelText: field['label']),
          validator: (value) =>
              value == null || value.isEmpty ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }).toList();
}
}
