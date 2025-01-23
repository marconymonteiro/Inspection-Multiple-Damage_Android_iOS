import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class PdfGenerator {
  
  // Método auxiliar para carregar ícones
  Future<pw.MemoryImage> _loadIcon(String assetPath) async {
    final iconBytes = await rootBundle.load(assetPath);
    return pw.MemoryImage(iconBytes.buffer.asUint8List());
  }
  
  // Gera um arquivo PDF com base nos dados fornecidos
  Future<File> generatePdf({
    required String name,
    required String cargo,
    required String serialNumber,
    required String invoiceNumber,
    required String reportDate,
    required String codigo,
    required bool hasDamage,
    required String damageDescription,
    required List<Map<String, dynamic>> damagesData, // Lista de danos
    required List<File> photosCarga,
    required List<File> photosDamage,
    required String equipment,
    required String freight,
    required String plate,
    required String driverID,
    required String model,
    required String sanyRef,
    required String invoiceQtty,
    required String invoiceItems,
  }) async {
    final pdf = pw.Document();
    final emissionDateTime = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    String _formatReportDate(String reportDate) {
      try {
        final parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(reportDate);
        return DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
      } catch (e) {
        print('Erro ao formatar data: $e');
        return reportDate;
      }
    }

    try {
      // Carregar a logo da empresa dos assets
      final logoBytes = await rootBundle.load('assets/logo_cliente.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      final emailIcon = await _loadIcon('assets/email_icon.png');
      final locationIcon = await _loadIcon('assets/location_icon.png');
      final phoneIcon = await _loadIcon('assets/phone_icon.png');
      final instagramIcon = await _loadIcon('assets/instagram_icon.png');
      final websiteIcon = await _loadIcon('assets/website_icon.png');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Cabeçalho
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(logoImage, width: 60, height: 60),
                      pw.Text(
                        'Relatório de Inspeção',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Divider(),
                ],
              ),
              pw.SizedBox(height: 20),
              // Informações Gerais
              pw.Text('Informações do Serviço', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: pw.FixedColumnWidth(180),
                  // 0: pw.FlexColumnWidth(),
                  1: pw.FlexColumnWidth(),
                },
                headers: ['Item', 'Informação'],
                data: [
                  ['Data do Relatório', _formatReportDate(reportDate)],
                  ['Código', codigo],
                  ['Equipamento', equipment],
                  ['Transportadora', freight],
                  ['Placas', plate],
                  ['Nome', name],
                  ['CPF', driverID],
                  ['Modelo', model],
                  ['Máquina', cargo],
                  ['Número de Série', serialNumber],
                  ['Nota Fiscal', invoiceNumber],
                  ['Referência SANY', sanyRef],
                  ['Volumes Totais na NF', invoiceQtty],
                  ['Volumes de Partes/Peças', invoiceItems],
                ],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
                cellHeight: 25,
                cellStyle: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              // Fotos de Carga
              pw.Text('Fotos da Carga', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              photosCarga.isNotEmpty
                  ? pw.Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: photosCarga.map((photo) {
                        final image = pw.MemoryImage(photo.readAsBytesSync());
                        return pw.Image(image, width: 180, height: 180);
                      }).toList(),
                    )
                  : pw.Text('Nenhuma foto disponível.', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 20),
              // Descrição de Danos e Fotografias
              pw.Text('Danos Registrados', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              damagesData.isNotEmpty
                  ? pw.Column(
                      children: damagesData.map((damage) {
                        final photos = damage['photos'] as List<File>;
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Descrição: ${damage['description']}',
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: photos.map((photo) {
                                final image = pw.MemoryImage(photo.readAsBytesSync());
                                return pw.Image(image, width: 180, height: 180);
                              }).toList(),
                            ),
                            pw.SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    )
                  : pw.Text('Nenhum dano registrado.', style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 20),
                      // Texto adicional
                      pw.Text(
                        'As informações contidas neste relatório são de propriedade exclusiva da Iron Máquinas. Sua divulgação não autorizada pode resultar em sanções legais.',
                        style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 20),

                      pw.Text(
                        'Relatório emitido em $emissionDateTime',
                        style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 20),

                      // Cartão de contato
                      pw.Text(
                        'Entre em contato conosco',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 20),

                       pw.Text(
                        'Camila Nogueira',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                       pw.Text(
                        'Diretora',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      _buildContactCard(emailIcon, locationIcon, phoneIcon, instagramIcon, websiteIcon),
            ];
          },

            footer: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 10),
                child: pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                ),
              );
            },

        ),
      );

      // Gerar o caminho para salvar o PDF
      final outputDir = await getApplicationDocumentsDirectory();
      final formattedDate = DateFormat('dd-MM-yyyy_HHmm').format(DateTime.now());
      final outputFile = File('${outputDir.path}/IronMaquinas_${serialNumber}_${invoiceNumber}_$formattedDate.pdf');

      // Salvar o arquivo PDF
      await outputFile.writeAsBytes(await pdf.save());
      return outputFile;
    } catch (e) {
      throw Exception('Erro ao gerar PDF: $e');
    }
  }
  pw.Widget _buildContactCard(
    pw.MemoryImage emailIcon,
    pw.MemoryImage locationIcon,
    pw.MemoryImage phoneIcon,
    pw.MemoryImage instagramIcon,
    pw.MemoryImage websiteIcon,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(children: [pw.Image(emailIcon, width: 14), pw.SizedBox(width: 8), pw.Text('contato@ironmaquinas.com.br')]),
        pw.Row(children: [pw.Image(locationIcon, width: 16), pw.SizedBox(width: 8), pw.Text('Av. Augusto Ruschi, 1210. Balneário de Carapebus, Serra - ES, 29164-830')]),
        pw.Row(children: [pw.Image(phoneIcon, width: 16), pw.SizedBox(width: 8), pw.Text('+55 27 90000-0000')]),
        pw.Row(children: [pw.Image(instagramIcon, width: 16), pw.SizedBox(width: 8), pw.Text('@ironmaquinas')]),
        pw.Row(children: [pw.Image(websiteIcon, width: 16), pw.SizedBox(width: 8), pw.Text('ironmaquinas.com.br')]),
      ],
    );
}
}
