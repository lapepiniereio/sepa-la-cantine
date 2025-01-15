import 'package:xml/xml.dart';

class SepaService {
  bool isValidSepaFile(XmlDocument document) {
    try {
      final root = document.rootElement;
      if (root.name.local != 'Document') return false;

      final pain = root.findElements('pain.001.001.02');
      if (pain.isEmpty) return false;

      final pmtInf = pain.first.findElements('PmtInf');
      if (pmtInf.isEmpty) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  bool isAlreadyInstant(XmlDocument document) {
    try {
      final pmtInfElements = document.findAllElements('PmtInf');
      for (var pmtInf in pmtInfElements) {
        final pmtTpInf = pmtInf.findElements('PmtTpInf').firstOrNull;
        if (pmtTpInf != null) {
          final lclInstrm = pmtTpInf.findElements('LclInstrm').firstOrNull;
          if (lclInstrm != null) {
            final cd = lclInstrm.findElements('Cd').firstOrNull;
            if (cd != null && cd.text == 'INST') {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void convertToInstantSepa(XmlDocument document) {
    final pmtInfElements = document.findAllElements('PmtInf');

    for (var pmtInf in pmtInfElements) {
      final pmtTpInf = pmtInf.findElements('PmtTpInf').firstOrNull;
      if (pmtTpInf != null) {
        final svcLvl = pmtTpInf.findElements('SvcLvl').firstOrNull;
        if (svcLvl != null) {
          final lclInstrm = XmlElement(XmlName('LclInstrm'));
          final lclInstrmCd = XmlElement(XmlName('Cd'));
          lclInstrmCd.children.add(XmlText('INST'));
          lclInstrm.children.add(lclInstrmCd);

          final svcLvlIndex = pmtTpInf.children.indexOf(svcLvl);
          pmtTpInf.children.insert(svcLvlIndex + 1, lclInstrm);
        }
      }
    }
  }
}
